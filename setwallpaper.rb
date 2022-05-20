#!/usr/bin/env ruby

require 'pp'

module SetWallpaper
  def self.wallpaper_map
    {'HDMI-A-0' => '~/Nextcloud/wallpapers/cat-rain-dream-cyberpunk-city-4k-02-3840x2400.jpg',
     'DisplayPort-4' => '~/Nextcloud/wallpapers/glowing-with-neon-ye-3840x2400.jpg',
     'eDP' => '~/Nextcloud/wallpapers/way-to-retro-city-4k-r6-2560x1600.jpg'}
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
    puts out
  end
end

SetWallpaper.monitor_map.each do |kde_screen, monitor|
  SetWallpaper.set_wallpaper(kde_screen, SetWallpaper.wallpaper_map[monitor])
end

