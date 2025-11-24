require 'uri'
require 'net/http'
require 'json'
require 'faker'
# Required to download files from a URL into Active Storage
require 'open-uri'


puts "Cleaning database..."
# NOTE: Active Storage attachments are automatically cleaned up when the record is destroyed
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

# Store poster paths to use for list photos later
all_poster_paths = []

results.each do |movie_data|
  Movie.create!(
    title: movie_data["title"],
    overview: movie_data["overview"],
    rating: movie_data["vote_average"],
    # We still save poster_url, but now Active Storage is used for the list cover image
    poster_url: "https://image.tmdb.org/t/p/w500#{movie_data["poster_path"]}"
  )
  all_poster_paths << movie_data["poster_path"]
end

puts "Seeded #{Movie.count} movies."
puts "-----------------------------------"


puts "Creating 4 Lists and attaching cover photos..."
list_names = ["Must Watch", "Guilty Pleasures", "Family Night", "Sci-Fi Favorites"]
lists = []

# Select 4 random poster paths for the list covers
list_poster_paths = all_poster_paths.sample(4)

list_names.each_with_index do |name, index|
  # 1. Get the poster URL for the list
  poster_path = list_poster_paths[index]
  remote_image_url = "https://image.tmdb.org/t/p/w500#{poster_path}"

  # 2. Open the URL to get the file IO object
  file = URI.open(remote_image_url)

  # 3. Create the list
  list = List.create!(name: name)

  # 4. Attach the remote file to the List's 'photo' attachment
  # The filename is set to the last part of the URL path for simplicity
  filename = File.basename(URI.parse(poster_path).path)

  list.photo.attach(
    io: file, # The file IO object from the remote URL
    filename: filename,
    content_type: 'image/jpeg' # Or get content_type dynamically if necessary
  )

  lists << list
  puts "Created list: #{name} with photo attached."
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
