require 'color'
require 'hue'
require 'miro'
require 'nokogiri'
require 'open-uri'

url = 'http://www.eurovision.tv/live/live_story_the_grand_final'

hue = Hue::Client.new

def colour_to_hue(colour)
  r = colour.r
  g = colour.g
  b = colour.b
  max = [r, g, b].max
  min = [r, g, b].min
  delta = max - min
  v = max * 100

  if max != 0.0
    s = delta / max * 100
  else
    s = 0.0
  end

  if s == 0.0
    h = 0.0
  else
    if r == max
      h = (g - b) / delta
    elsif g == max
      h = 2 + (b - r) / delta
    elsif b == max
      h = 4 + (r - g) / delta
    end

    h *= 60.0

    if h < 0
      h += 360.0
    end
  end

  {
    hue: (h * 182.04).round,
    saturation: (s / 100.0 * 255.0).round,
    bri: (v / 100.0 * 255.0).round
  }
end

last_entry = nil
current_country = nil

while true do
  doc = Nokogiri::HTML(open(url))
  new_country = doc.xpath('//*[@data-filter-tag]').first.attr('data-filter-tag')
  puts "Detected change to #{new_country} on the live blog" if (new_country != current_country && new_country != last_entry)
  last_entry = new_country
  if new_country != current_country
    flag_file = "flags/#{new_country.gsub(' ', '_')}.png"
    if File.exist? flag_file
      puts "#{new_country} appears to actually be a country, so making a transition"
      current_country = new_country
      colours = Miro::DominantColors.new(flag_file)
      hue.lights.each_with_index do |light, i|
        light.on!
        rgb = colours.to_rgb[i]
        target_colour = Color::RGB.new(rgb[0], rgb[1], rgb[2])
        puts "Transitioning #{light.name} to #{rgb}"
        light.set_state(colour_to_hue(target_colour), transition: 5)
      end
    end
  end
  sleep 26
end
