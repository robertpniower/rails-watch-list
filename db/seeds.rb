require 'uri'
require 'net/http'
require 'json'
require 'faker'


puts "Cleaning database..."
Bookmark.destroy_all
List.destroy_all
Movie.destroy_all

puts "Fetching and seeding movies from TMDB (Top Rated)..."

url = URI("https://tmdb.lewagon.com/movie/top_rated")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Get.new(url)
request["accept"] = 'application/json'

response = http.request(request)

data_hash = JSON.parse(response.body)
results = data_hash["results"]

results.each do |movie_data|
  Movie.create!(
    title: movie_data["title"],
    overview: movie_data["overview"],
    rating: movie_data["vote_average"],

    poster_url: "https://image.tmdb.org/t/p/w500#{movie_data["poster_path"]}"
  )
end

puts "Seeded #{Movie.count} movies."
puts "-----------------------------------"



puts "Creating 4 Lists..."
list_names = ["Must Watch", "Guilty Pleasures", "Family Night", "Sci-Fi Favorites"]
lists = []

list_names.each do |name|
  list = List.create!(name: name)
  lists << list
  puts "Created list: #{name}"
end

puts "-----------------------------------"

puts "Creating Bookmarks (4-6 movies per list)..."


all_movies = Movie.all


if all_movies.count < 10
  puts "Warning: Not enough movies fetched to fully populate all lists."
end

lists.each do |list|

  num_movies_to_bookmark = rand(4..6)


  movies_for_list = all_movies.sample(num_movies_to_bookmark)

  movies_for_list.each do |movie|
    Bookmark.create!(
      comment: Faker::Lorem.sentence(word_count: 5, supplemental: true),
      movie: movie,
      list: list
    )
    puts "Bookmarked '#{movie.title.truncate(20)}' to list '#{list.name}'"
  end
end

puts "--- Seeding Complete ---"
puts "Total Lists: #{List.count}"
puts "Total Bookmarks: #{Bookmark.count}"
