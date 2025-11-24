class ListsController < ApplicationController

  def index
    @lists = List.all
  end

  def show
    @list = List.find(params[:id])
    # @bookmark = Bookmark.find(@list.id)
    @bookmark_new = Bookmark.new
    @movies = @list.movies

  end

  def new
    @list = List.new
  end

  def create
    @list = List.new(list_params)
    @list.save
    if @list.save
      redirect_to list_path(@list)
    else
      render "lists/new", status: :unprocessable_entity
    end
  end

  def list_params
    params.require(:list).permit(:name, :photo)
  end

  end
