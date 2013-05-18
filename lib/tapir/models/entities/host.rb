module Tapir
  module Entities
    class Host < Base
      field :ip_address, type: String

      has_many :net_svcs

      validates_uniqueness_of :ip_address


      #
      # This method is highly questionable, but folks generally refer to a host
      # by its ip address(es), and thus, this makes tasks easier to code.
      #
      def name
        ip_address
      end

    end
  end
end