module Tapir
  module Entities
    class LinkedinAccount < Base 
      include TenantAndProjectScoped
    end
  end
end