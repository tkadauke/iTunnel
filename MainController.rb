require 'osx/cocoa'
require 'yaml'

class MainController < OSX::NSWindowController
  attr_reader :status_menu
  attr_reader :tunnels
  attr_accessor :loaded
   
  def awakeFromNib
    @status_menu = OSX::NSMenu.alloc.init
    load_config
    create_status_bar
  end
  
  def set_status_icon(icon)
    @statusItem.setImage get_icon(icon)
  end
  
  def get_icon(icon)
    path = OSX::NSBundle.mainBundle.pathForResource_ofType("icon-#{icon}", "png")
    OSX::NSImage.alloc.initByReferencingFile(path)
  end
  
  def toggle_tunnel(sender)
    tunnel = self.tunnels[sender.tag]
    if tunnel.open?
      tunnel.close
      sender.setState(OSX::NSOffState)
    else
      tunnel.open
      sender.setState(OSX::NSOnState)
      wait_and_open_browser(tunnel)
    end
  end
  
  def quit(sender)
    @tunnels.each do |tunnel|
      tunnel.close
    end
    OSX::NSApp.stop(nil)
  end

private
  def load_config
    config = YAML.load(File.read("#{ENV['HOME']}/.itunnels"))
    
    @tunnels = config.map do |hash|
      Tunnel.new(hash['name'], hash['login'], hash['host'], hash['remote_port'], hash['local_port'], hash['url'])
    end
  end
  
  def wait_and_open_browser(tunnel)
    # apparently we can't use sleep in RubyCocoa, because things crash reliably when we do
    system "sleep 2; open http://localhost:#{tunnel.local_port}#{tunnel.url}"
  end
  
  def create_status_bar
    @statusItem = OSX::NSStatusBar.systemStatusBar.statusItemWithLength(OSX::NSVariableStatusItemLength)
    set_status_icon 'itunnel-small'
    @statusItem.setHighlightMode true
    @statusItem.setMenu @status_menu
    @statusItem.setTarget self
    update_menu
  end
   
  def update_menu(hosts_list = nil)
    index = 0
    self.tunnels.each do |tunnel|
      item = @statusItem.menu.insertItemWithTitle_action_keyEquivalent_atIndex_(tunnel.name, "toggle_tunnel:", "", index)
      item.setTarget self
      item.setTag index
      index += 1
    end
    @statusItem.menu.insertItem_atIndex(OSX::NSMenuItem.separatorItem, index)

    item = @statusItem.menu.insertItemWithTitle_action_keyEquivalent_atIndex_("Quit", "quit:", "", index + 1)
    item.setTarget self
  end
end
