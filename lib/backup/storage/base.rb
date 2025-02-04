module Backup
  module Storage
    class Base
      include Config::Helpers

      ##
      # Base path on the remote where backup package files will be stored.
      attr_accessor :path

      ##
      # Number of backups to keep or time until which to keep.
      #
      # If an Integer is given it sets the limit to how many backups to keep in
      # the remote location. If exceeded, the oldest will be removed to make
      # room for the newest.
      #
      # If a Time object is given it will remove backups _older_ than the given
      # date.
      #
      # @!attribute [rw] keep
      #   @param [Integer|Time]
      #   @return [Integer|Time]
      attr_accessor :keep

      attr_reader :model, :package, :storage_id

      ##
      # +storage_id+ is a user-defined string used to uniquely identify
      # multiple storages of the same type. If multiple storages of the same
      # type are added to a single backup model, this identifier must be set.
      # This will be appended to the YAML storage file used for cycling backups.
      def initialize(model, storage_id = nil, &block)
        @model = model
        @package = model.package
        @storage_id = storage_id.to_s.gsub(/\W/, "_") if storage_id

        load_defaults!
        instance_eval(&block) if block_given?
      end

      def perform!
        Logger.info "#{storage_name} Started..."
        transfer!
        if keep.to_i > 0 || keep.is_a?(Time)
          raise "Storage option \"keep\" set, but not supported." unless respond_to?(:cycle!)
          cycle!
        end
        Logger.info "#{storage_name} Finished!"
      end

      private

      ##
      # Return the remote path for the current or given package.
      def remote_path(pkg = package)
        path.empty? ? File.join(pkg.trigger, pkg.time) :
                      File.join(path, pkg.trigger, pkg.time)
      end
      alias :remote_path_for :remote_path

      def storage_name
        @storage_name ||= self.class.to_s.sub("Backup::", "") +
          (storage_id ? " (#{storage_id})" : "")
      end
    end
  end
end
