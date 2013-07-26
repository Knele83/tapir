def name
  "nmap_scan_web"
end

def pretty_name
  "Nmap Scan Web"
end

## Returns a string which describes what this task does
def description
  "This task runs an nmap scan on the target host or domain to detect common web ports."
end

## Returns an array of types that are allowed to call this task
def allowed_types
  [ Entities::Domain, 
    Entities::Host, 
    Entities::NetBlock]
end

## Returns an array of valid options and their description/type for this task
def allowed_options
 []
end

def setup(entity, options={})
  super(entity, options)
end

## Default method, subclasses must override this
def run
  super
  
  nmap_options = @options['nmap_options']
  
  if @entity.kind_of? Entities::Host
    to_scan = @entity.name
  elsif @entity.kind_of? Entities::NetBlock
    to_scan = @entity.range
  elsif @entity.kind_of? Entities::Domain
    to_scan = @entity.name
  else
    raise ArgumentError, "Unknown entity type"
  end
  
  @rand_file_path = "#{Dir::tmpdir}/nmap_scan_#{rand(100000000)}.xml"
  
  # shell out to nmap and run the scan
  @task_logger.log "scanning #{to_scan} and storing in #{@rand_file_path}"
  @task_logger.log "nmap options: #{nmap_options}"
  
  nmap_string = "nmap #{to_scan} #{nmap_options} -P0 -p 80,443,8080,8081 -oX #{@rand_file_path}"
  @task_logger.log "calling nmap: #{nmap_string}"
  safe_system(nmap_string)
  
  # Gather the XML and parse
  @task_logger.log "Raw Result:\n #{File.open(@rand_file_path).read}"
  @task_logger.log "Parsing #{@rand_file_path}"

  parser = Nmap::Parser.parsefile(@rand_file_path)

  # Create entitys for each discovered service
  parser.hosts("up") do |host|

    @task_logger.log "Handling nmap data for #{host.addr}"

    # Handle the case of a netblock or domain - where we will need to create host entity(s)
    if @entity.kind_of? Entities::NetBlock or @entity.kind_of? Entities::Domain
      @host_entity = create_entity(Entities::Host, {:name => host.addr })
      #@host_entity.domains << @entity
    else
      @host_entity = @entity # We already have a host
    end

    [:tcp, :udp].each do |proto_type|
      host.getports(proto_type, "open") do |port|
      @task_logger.log "Creating Service: #{port}"
      create_entity(Entities::NetSvc, {
        :name => "#{@entity.name}:#{port.num}/#{port.proto}",
        :host_id => @host_entity.id,
        :port_num => port.num,
        :proto => port.proto,
        :fingerprint => "#{port.service.name} #{port.service.product} #{port.service.version}"})
      end

    end
  
  end
end

def cleanup
  super
  File.delete(@rand_file_path)
end
