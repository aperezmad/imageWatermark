# The program add a watermark massively to the images in the input folder.
#
# Requires ImageMagick installed on the host system.
#
# The image disposition is automatically detected and different watermark images are used accordingly.
# These images are resized proportionally to match the image dimensions, note that the watermark resolution should be
# greater than the ones of the images.
#
# Folder structure:
#
# root_folder
#     |- input_folder   Where the images are stored originally.
#     |- output_foder   Processed images end here.
#     |- logo_folder    Where watermark images are stored.
#     |- temp_folder    Temp folder for processing.
#
# Author::    Alberto Pérez Madruga  (mailto:aperez@brujuleo.es)
# License::   Distributes under the same terms as Ruby

# Path configuration
@root_path = '/Users/albertoperez/Desktop/gp-pics'

@original_path = "#{@root_path}/original"
@inbox_path = "#{@root_path}/inbox"

@temp_path = "#{@root_path}/temp"
@output_path = "#{@root_path}/big"
@logo_path = "#{@root_path}/logo"


# Logo images for each disposition (square, horizontal, vertical) logo images must be greater.
@logo = {s: 'gp-s.png', h: 'gp-h.png', v: 'gp-v.png'}

# Blend level (transparency)
@blend = 30

# To store test times
@test_time = 0

require 'mini_magick'
require 'fileutils'

def copy_path(src,dst)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(src, dst)
end

def mask(value,len,char,just=0)
  if just == 0
    return value.to_s.rjust(len,char)
  else
    return value.to_s.ljust(len,char)
  end
end


def img_info(img)
  image = MiniMagick::Image.open("#{img}")

  # Get aspect ratio
  ratio = image[:width].fdiv(image[:height])

  # Get disposition
  case ratio
    when 0..0.6 then disp = 'v'
    when 1.60001..6 then disp = 'h'
    #when 0.60001..1.6 then disp = 's'
    else disp = 's'
  end

  info = { x: image[:width], y: image[:height], ratio: ratio ,disp: disp }

  return info
end

def format_time(time)
  min = time.fdiv(60)
  if min >= 60
    return "#{'%.1f' % (min/60)}h"
  else
    return "#{'%.1f' % min}m"
  end
end

def move_file(img)
  FileUtils.mv(img, "#{@original_path}/")
  #puts "Salida: #{img} #{@output_path}/"
end

def watermark(img,test=false)

  # For time estimation
  start = Time.now

  output_path = test ? @temp_path : @output_path

  info = img_info(img)

  # Create output dir if needed
  FileUtils.mkdir_p("#{@output_path}")
  FileUtils.mkdir_p("#{@temp_path}")

  case info[:disp]
    when 's'

      # (5k x 5k)px ratio: 1 [fix to smaller side]
      if info[:x]>info[:y]
        lx = info[:y]
        ly = info[:y]
      else
        lx = info[:x]
        ly = info[:x]
      end

    when 'v'
      # (2k5 x 5k)px ratio: 0.5 [fix to smaller side and resize bigger proportionally]
      lx = info[:x]
      ly = (info[:x]/0.5).to_int

    when 'h'
      # (5k x 2k5)px ratio: 2 [fix to smaller side and resize bigger proportionally]
      lx = (2*info[:y]).to_int
      ly = info[:y]

  end

  # Convert logo to destination size
  convert_cmd = "convert #{@logo_path}/#{@logo[info[:disp].to_sym]} -resize #{lx}x#{ly} #{@temp_path}/tmp-logo.png"
  #puts convert_cmd
  system(convert_cmd)

  # Add logo centered over the image
  watermark_cmd = "composite -compose screen -gravity center -blend #{@blend} #{@temp_path}/tmp-logo.png #{img} #{output_path}/#{File.basename(img)}"
  #puts watermark_cmd
  system(watermark_cmd)

  finish = Time.now
  @test_time = finish-start

end

def display_info(verbose)

  totals = {count: 0, max_x: 0, max_y: 0, h: 0, v: 0, s: 0, time: ''}

  Dir.glob("#{@inbox_path}/*.jpg") do |img_file|
    info = img_info(img_file)
    if verbose
      puts "image: #{img_file} x: #{info[:x]} y: #{info[:y]} ratio: #{mask(info[:ratio],18,'0',1)} disp: #{info[:disp]}"
    end
    if info[:x] > totals[:max_x] then  totals[:max_x] = info[:x] end
    if info[:y] > totals[:max_y] then  totals[:max_y] = info[:y] end
    totals[:count] += 1
    totals[info[:disp].to_sym] += 1
  end


  watermark(Dir.glob("#{@inbox_path}/*.jpg")[0],true)

  totals[:time] = format_time(totals[:count]*@test_time)

  puts "\nFiles:\t\t#{mask(totals[:count],6,' ')}\nMax Width:\t#{mask(totals[:max_x],6,' ')}\nMax Height:\t#{mask(totals[:max_y],6,' ')}\nSquare:\t\t#{mask(totals[:s],6,' ')}\nHorizontal:\t#{mask(totals[:h],6,' ')}\nVertical:\t#{mask(totals[:v],6,' ')}\n\nEstimated time:\t#{totals[:time]}\n"
end

def do_watermarks
  start = Time.now

  files = 0
  Dir.glob("#{@inbox_path}/*.jpg") do |img_file|
    print File.basename(img_file)
    watermark(img_file)
    move_file(img_file)
    puts ' .. OK'
    files += 1
  end

  finish = Time.now

  diff = finish - start

  puts "\n#{files} files processed in #{'%.1f' % (diff/60)}m (#{'%.1f' % (diff/files)} s/file)"
end


#############
# Main code #
#############

#display_info(true)

do_watermarks
