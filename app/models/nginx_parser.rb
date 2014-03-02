class NginxParser
  def initialize(path)
    unless File.exists?(path)
      return false
    end
    f = File.open(path)
    @lines = f.readlines
  end

  def parse
    lines = @lines
    lines.reject! { |c| c.empty? }
    upstream_blocks = Hash.new
    server_blocks = Hash.new
    events_blocks = Hash.new
    http_blocks = Hash.new
    out_of_block = Array.new

    ptr = 0
    while (ptr <= lines.count) do
      line = lines[ptr]
      unless line.nil?
        line = line.gsub("\n", "")
        if line.split(" ")[0] == "upstream" and line.include?("{")
          upstr_name = line.match(/upstream ([a-zA-Z]+) {/)[1]
          servers = []
          ptr += 1
          while (lines[ptr].split(" ")[0] == "server") do
            line = lines[ptr].split(" ")
            address = line[1]
            parameters = line[2..-1]
            parameters.map! do |e|
              e = e.gsub(/;/, '')
              e = e.split("=")
            end
            servers.push({:address => address, :parameters => parameters})
            ptr += 1
          end
          upstream_blocks[upstr_name] = servers
        elsif line.split(" ")[0] == "events" and line.include?("{")
          ptr += 1
          items = []
          while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
            line = lines[ptr].split(" ")
            key = line[0]
            values = line[1..-1]
            unless values.nil?
              i = 1
              if line.nil?
                ptr += 1
                next
              elsif values.nil?
                ptr += 1
                next
              end
              while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                if i <= values.count
                  i += 1
                else
                  ptr += 1
                  if values.is_a?(String)
                    values = values.split(" ") + lines[ptr].split(" ")
                  else
                    values = values.to_a + lines[ptr].split(" ")
                  end
                  i = 1
                end
              end
              values.reject! { |c| c.empty? }
              values.map! {|e| e.gsub(/;/, '') }
            end
            unless key.nil? or key[0] == "#"
              items.push({:key => key, :values => values})
            end
            ptr += 1
          end
          events_blocks[events_blocks.count.to_i] = items
        elsif line.split(" ")[0] == "http" and line.include?("{")
          ptr += 1
          http_server_blocks = Hash.new
          http_upstream_blocks = Hash.new
          mainitems = []
          while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
            unless lines[ptr].nil?
              line = lines[ptr].split(" ")
              if line.split(" ")[0] == "server" and line.include?("{")
                ptr += 1
                items = []
                while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
                  block = []
                  line = lines[ptr].split(" ")
                  if line[0] == "location"
                    ptr += 1
                    location_items = []
                    location_name = line.join(" ")
                    while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
                      line = lines[ptr].split(" ")
                      key = line[0]
                      values = line[1..-1]
                      i = 1
                      if line.nil?
                        ptr += 1
                        next
                      elsif values.nil?
                        ptr += 1
                        next
                      end
                      while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                        if i <= values.count
                          i += 1
                        else
                          ptr += 1
                          if values.is_a?(String)
                            values = values.split(" ") + lines[ptr].split(" ")
                          else
                            values = values.to_a + lines[ptr].split(" ")
                          end
                          i = 1
                        end
                      end
                      values.reject! { |c| c.empty? }
                      values.map! {|e| e.gsub(/;/, '') }
                      unless key.nil? or key[0..0] == "#"
                        location_items.push({:key => key, :values => values})
                      end
                      ptr += 1
                    end
                    ptr += 1
                    items.push({:key => location_name, :values => location_items})
                  else
                    key = line[0]
                    values = line[1..-1]
                    unless values.nil?
                      i = 1
                      if line.nil?
                        ptr += 1
                        next
                      elsif values.nil?
                        ptr += 1
                        next
                      end
                      while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                        if i <= values.count
                          i += 1
                        else
                          ptr += 1
                          if values.is_a?(String)
                            values = values.split(" ") + lines[ptr].split(" ")
                          else
                            values = values.to_a + lines[ptr].split(" ")
                          end
                          i = 1
                        end
                      end
                      values.reject! { |c| c.empty? }
                      values.map! {|e| e.gsub(/;/, '') }
                    end
                    unless key.nil? or key[0] == "#"
                      items.push({:key => key, :values => values})
                    end
                    ptr += 1
                  end
                end
                ptr += 1
                http_server_blocks[http_server_blocks.count.to_i] = items
              elsif line.split(" ")[-1] == "{"
                key = line
                kvalues = Array.new
                ptr += 1
                while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
                  line = lines[ptr].split(" ")
                  key = line[0]
                  values = line[1..-1]
                  unless values.nil?
                    i = 1
                    if line.nil?
                      ptr += 1
                      next
                    elsif values.nil?
                      ptr += 1
                      next
                    end
                    while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                      if i <= values.count
                        i += 1
                      else
                        ptr += 1
                        if values.is_a?(String)
                          values = values.split(" ") + lines[ptr].split(" ")
                        else
                          values = values.to_a + lines[ptr].split(" ")
                        end
                        i = 1
                      end
                    end
                    values.reject! { |c| c.empty? }
                    values.map! {|e| e.gsub(/;/, '') }
                  end
                  kvalues.push({:key => key, :values => values})
                end
                out_of_block.push({:key => key, :values => values})
              elsif line.split(" ")[0] == "upstream" and line.include?("{")
                upstr_name = lines[ptr].match(/upstream ([a-zA-Z]+) {/)[1]
                servers = []
                ptr += 1
                while (lines[ptr].split(" ")[0] == "server") do
                  line = lines[ptr].split(" ")
                  address = line[1]
                  parameters = line[2..-1]
                  parameters.map! do |e|
                    e = e.gsub(/;/, '')
                    e = e.split("=")
                  end
                  servers.push({:address => address, :parameters => parameters})
                  ptr += 1
                end
                ptr += 1
                http_upstream_blocks[upstr_name] = servers
              else
                line = lines[ptr].split(" ")
                key = line[0]
                values = line[1..-1]
                if line.nil?
                  ptr += 1
                  next
                elsif values.nil?
                  ptr += 1
                  next
                end
                unless values.nil?
                  i = 1
                  while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                    if i <= values.count
                      i += 1
                    else
                      ptr += 1
                      if values.is_a?(String)
                        values = values.split(" ") + lines[ptr].split(" ")
                      else
                        values = values.to_a + lines[ptr].split(" ")
                      end
                      i = 1
                    end
                  end
                  values.reject! { |c| c.empty? }
                  values.map! {|e| e.gsub(/;/, '') }
                end
                unless key.nil? or key[0] == "#"
                  mainitems.push({:key => key, :values => values})
                end
                ptr += 1
              end
            end
          end
          http_blocks[http_blocks.count.to_i] = {:main => mainitems, :upstream_blocks => http_upstream_blocks, :server_blocks => http_server_blocks}
        elsif line.split(" ")[0] == "server" and line.include?("{")
          ptr += 1
          items = []
          while (!lines[ptr].include?("}")) do
            block = []
            line = lines[ptr].split(" ")
            if line[0] == "location"
              ptr += 1
              location_items = []
              location_name = line.join(" ")
              while (!lines[ptr].include?("}")) do
                line = lines[ptr].split(" ")
                key = line[0]
                values = line[1..-1]
                i = 1
                if line.nil?
                  ptr += 1
                  next
                elsif values.nil?
                  ptr += 1
                  next
                end
                while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                  if i <= values.count
                    i += 1
                  else
                    ptr += 1
                    if values.is_a?(String)
                      values = values.split(" ") + lines[ptr].split(" ")
                    else
                      values = values.to_a + lines[ptr].split(" ")
                    end
                    i = 1
                  end
                end
                values.reject! { |c| c.empty? }
                values.map! {|e| e.gsub(/;/, '') }
                unless key.nil? or key[0..0] == "#"
                  location_items.push({:key => key, :values => values})
                end
                ptr += 1
              end
              items.push({:key => location_name, :values => location_items})
            else
              key = line[0]
              values = line[1..-1]
              unless values.nil?
                i = 1
                if line.nil?
                  ptr += 1
                  next
                elsif values.nil?
                  ptr += 1
                  next
                end
                while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                  if i <= values.count
                    i += 1
                  else
                    ptr += 1
                    if values.is_a?(String)
                      values = values.split(" ") + lines[ptr].split(" ")
                    else
                      values = values.to_a + lines[ptr].split(" ")
                    end
                    i = 1
                  end
                end
                values.reject! { |c| c.empty? }
                values.map! {|e| e.gsub(/;/, '') }
              end
              unless key.nil? or key[0] == "#"
                items.push({:key => key, :values => values})
              end
            end
            ptr += 1
          end
          server_blocks[server_blocks.count.to_i] = items
        elsif line[-1] == "{"
          mkey = line
          kvalues = Array.new
          ptr += 1
          while (!lines[ptr].to_s.include?("}") and ptr <= lines.count) do
            line = lines[ptr].split(" ")
            key = line[0]
            values = line[1..-1]
            unless values.nil?
              i = 1
              if line.nil?
                ptr += 1
                next
              elsif values.nil?
                ptr += 1
                next
              end
              while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
                if i <= values.count
                  i += 1
                else
                  ptr += 1
                  if values.is_a?(String)
                    values = values.split(" ") + lines[ptr].split(" ")
                  else
                    values = values.to_a + lines[ptr].split(" ")
                  end
                  i = 1
                end
              end
              values.reject! { |c| c.empty? }
              values.map! {|e| e.gsub(/;/, '') }
              ptr += 1
            end
            kvalues.push({:key => key, :values => values})
          end
          out_of_block.push({:key => mkey, :values => kvalues})
        else
          line = lines[ptr].split(" ")
          key = line[0]
          values = line[1..-1]
          if line.nil?
            ptr += 1
            next
          elsif values.nil?
            ptr += 1
            next
          end
          unless values.nil?
            i = 1
            while !values[-i].to_s.include?(";") and !values[-i].to_s == "}"
              if i <= values.count
                i += 1
              else
                ptr += 1
                if values.is_a?(String)
                  values = values.split(" ") + lines[ptr].split(" ")
                else
                  p ptr
                  values = values.to_a + lines[ptr].split(" ")
                end
                i = 1
              end
            end
            values.reject! { |c| c.empty? }
            values.map! {|e| e.gsub(/;/, '') }
          end
          unless key.nil? or key[0] == "#" or key[0] == "}"
            out_of_block.push({:key => key, :values => values})
          end
        end
      end
      ptr += 1
    end
    return {:out_of_block => out_of_block, :event_blocks => events_blocks, :http_blocks => http_blocks, :upstream_blocks => upstream_blocks, :server_blocks => server_blocks}
  end
end
