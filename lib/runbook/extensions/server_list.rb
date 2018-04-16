module Runbook::Extensions
  module ServerList
    def server_list
      @server_list ||= []
    end

    def server(server)
      server_list.clear
      server_list << server
    end

    def servers(servers)
      server_list.clear
      servers.each { |server| server_list << server }
    end
  end

  Runbook::Step.prepend(ServerList)
end
