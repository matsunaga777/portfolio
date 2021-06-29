class ArticlesController < ApplicationController
  before_action :find_article, only: [:show, :edit, :update, :destroy]
  before_action :validate_user,only: [ :edit, :destroy]
  before_action :set_ranking,only: [ :index, :show]
  def index
    @articles = Article.order(created_at: :desc)
  end

  def show
    REDIS.zincrby "ranking", 1, "#{@article.id}"
  end

  def edit
  end

  def new
    @article=Article.new
  end

  def create
    @article = Article.new(article_params)
    @article.user_id=current_user.id
    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  def destroy
    if @article.destroy
      REDIS.zrem('ranking',@article.id)
      redirect_to root_path
    else
      redirect_to root_path
    end
  end

  def update
    if @article.update(article_params)
      redirect_to @article
    else
      redirect_to root_path
    end
  end

  private

  def find_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body)
  end

  def validate_user
    if @article.user_id!=current_user.id
        redirect_to root_path
        flash[:danger] = "not yours"
    end
  end

  def set_ranking
    ids = REDIS.zrevrangebyscore "ranking", "+inf", -1, limit: [0, 3]
      @ranking_articles = ids.map{ |id| Article.find(id) }
  end
end
