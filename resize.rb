@root_path = '/Users/albertoperez/Desktop/convert'
@input_path = "#{@root_path}/input"
@output_path = "#{@root_path}/output"
@width = 900
@height = 900


Dir.glob("#{@input_path}/*.jpg") do |img_file|
  file = File.basename(img_file)
  resize_cmd = "convert #{@input_path}/#{file} -resize #{@width}x#{@height} -gravity center -background white -extent #{@width}x#{@height} #{@output_path}/#{file}"

  puts file
  system(resize_cmd)
end