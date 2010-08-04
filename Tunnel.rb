class Tunnel
  attr_accessor :name, :login, :host, :remote_port, :local_port, :url

  def initialize(name, login, host, remote_port, local_port, url)
    @name, @login, @host, @remote_port, @local_port, @url = name, login, host, remote_port, local_port, url
  end

  def open
    command = "ssh -nN #{@login}@#{@host} -L#{local_port}:localhost:#{remote_port}"
    @pid = fork do
      exec command
    end
    @open = true
  end
  
  def open?
    @open
  end

  def close
    return unless @open
    
    Process.kill 'TERM', @pid
    Process.waitpid @pid
    @open = false
  end
end
