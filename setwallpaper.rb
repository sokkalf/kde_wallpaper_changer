#!/usr/bin/env ruby
require 'yaml'

module SetWallpaper
  def self.wallpaper_map
    #{'PHL 328P6V' => '~/Nextcloud/wallpapers/cat-rain-dream-cyberpunk-city-4k-02-3840x2400.jpg',
    # 'PHL 328P6VU' => '~/Nextcloud/wallpapers/glowing-with-neon-ye-3840x2400.jpg',
    # 'Laptop monitor' => '~/Nextcloud/wallpapers/way-to-retro-city-4k-r6-2560x1600.jpg'}
    YAML.load_file('wallpapers.yml')
  end

  def self.monitor_map
    # get list of screens as enumerated by KDE (negative numbers are disabled)
    kde_screens = %x{qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var allDesktops = desktops();for(i=0;i<allDesktops.length;i++){print(allDesktops[i].screen + " ")}'}.split.select{|x|x.to_i>=0}
    # guess that this list matches the order listed by xrandr
    monitors = %x{xrandr --listmonitors|grep -v Monitors}.split("\n").map{|x| x.split(" ")[3]}

    # connect them together
    monitor_map = kde_screens.zip(monitors).to_h
  end

  def self.set_wallpaper(monitor, filename)
    javascript = format(<<~JS, monitor.to_i, File.expand_path(filename))
      var allDesktops = desktops();
      for (i=0;i<allDesktops.length;i++)
      {
          d = allDesktops[i];
          if(d.screen == %i) {
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://%s');
          }
      }
    JS
    out = %x{qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "#{javascript}"}
  end

  def self.output_to_display
    wd = File.dirname(File.expand_path(__FILE__))
    out = %x{#{wd}/get_monitor_names.sh}
    out.split("\n").map{|x| output, type, *display_name = x.split(" ") ; {display_name.join(" ") => output}}.inject(:merge)
  end

  def self.set_wallpapers
    monitor_display_map = self.output_to_display
    wallpapers_to_set = self.wallpaper_map.filter_map do |monitor, wallpaper|
      display = monitor_display_map[monitor]
      kde_screen = monitor_map.invert[display]
      {monitor: monitor, wallpaper: wallpaper, display: display, screen: kde_screen} if display && kde_screen
    end

    wallpapers_to_set.each do |wp|
      SetWallpaper.set_wallpaper(wp[:screen], wp[:wallpaper])
    end
  end
end
SetWallpaper.set_wallpapers

