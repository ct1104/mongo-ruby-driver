# Copyright (C) 2018 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo
  module Operation
    class ParallelScan

      # A MongoDB parallelscan operation sent as an op message.
      #
      # @api private
      #
      # @since 2.5.2
      class OpMsg
        include Specifiable
        include Executable
        include SessionsSupported
        include CausalConsistencySupported

        # Execute the operation.
        #
        # @example
        #   operation.execute(server)
        #
        # @param [ Mongo::Server ] server The server to send the operation to.
        #
        # @return [ Mongo::Operation::ParallelScan::Result ] The operation result.
        #
        # @since 2.5.2
        def execute(server)
          result = Result.new(dispatch_message(server))
          process_result(result, server)
          result.validate!
        rescue Mongo::Error::SocketError => e
          e.send(:add_label, Mongo::Error::TRANSIENT_TRANSACTION_ERROR_LABEL) if session.in_transaction?
          raise e
        end

        private

        def selector(server)
          sel = { :parallelCollectionScan => coll_name, :numCursors => cursor_count }
          sel[:maxTimeMS] = max_time_ms if max_time_ms
          sel[:readConcern] = read_concern if read_concern
          sel
        end

        def message(server)
          Protocol::Msg.new(flags, options, command(server))
        end
      end
    end
  end
end
