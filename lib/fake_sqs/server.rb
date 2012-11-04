module FakeSQS
  class Server

    attr_reader :port, :host, :queues, :responder

    def initialize(options = {})
      @host      = options.fetch(:host)
      @port      = options.fetch(:port)
      @queues    = options.fetch(:queues)
      @responder = options.fetch(:responder)
    end

    def call(action, *args)
      public_send(action, *args)
    end

    # Actions for Queues

    def create_queue(params)
      name = params.fetch("QueueName")
      queue = queues.create(name, params)
      respond :CreateQueue do |xml|
        xml.QueueUrl url_for(queue.name)
      end
    end

    def delete_queue(name, params)
      queues.delete(name, params)
      respond :DeleteQueue
    end

    def list_queues(params)
      found = queues.list(params)
      respond :ListQueues do |xml|
        found.each do |queue|
          xml.QueueUrl url_for(queue.name)
        end
      end
    end

    def get_queue_url(params)
      name = params.fetch("QueueName")
      queue = queues.get(name, params)
      respond :GetQueueUrl do |xml|
        xml.QueueUrl url_for(queue.name)
      end
    end

    def get_queue_attributes(name, params)
    end

    def set_queue_attributes(name, params)
    end

    # Actions for Access Control on Queues

    def add_permission(name, params)
    end

    def remove_persmission(name, params)
    end

    # Actions for Messages

    def send_message(name, params)
      queue = queues.get(name)
      message = queue.send_message(params)
      respond :SendMessage do |xml|
        xml.MD5OfMessageBody message.md5
        xml.MessageId message.id
      end
    end

    def receive_message(name, params)
      queue = queues.get(name)
      messages = queue.receive_message(params)
      respond :ReceiveMessage do |xml|
        messages.each do |receipt, message|
          xml.Message do
            xml.MessageId message.id
            xml.ReceiptHandle receipt
            xml.MD5OfMessageBody message.md5
            xml.Body message.body
          end
        end
      end
    end

    def delete_message(name, params)
      queue = queues.get(name)

      receipt = params.fetch("ReceiptHandle")
      queue.delete_message(receipt)
      respond :DeleteMessage
    end

    def delete_message_batch(name, params)
      queue = queues.get(name)
      receipts = params.select { |k,v| k =~ /DeleteMessageBatchRequestEntry\.\d+\.ReceiptHandle/ }

      deleted = []

      receipts.each do |key, value|
        id = key.split('.')[1]
        queue.delete_message(value)
        deleted << params.fetch("DeleteMessageBatchRequestEntry.#{id}.Id")
      end

      respond :DeleteMessageBatch do |xml|
        deleted.each do |id|
          xml.DeleteMessageBatchResultEntry do
            xml.Id id
          end
        end
      end
    end

    def send_message_batch(name, params)
      queue = queues.get(name)

      messages = params.select { |k,v| k =~ /SendMessageBatchRequestEntry\.\d+\.MessageBody/ }

      results = {}

      messages.each do |key, value|
        id = key.split('.')[1]
        msg_id = params.fetch("SendMessageBatchRequestEntry.#{id}.Id")
        delay = params["SendMessageBatchRequestEntry.#{id}.DelaySeconds"]
        message = queue.send_message("MessageBody" => value, "DelaySeconds" => delay)
        results[msg_id] = message
      end

      respond :SendMessageBatch do |xml|
        results.each do |msg_id, message|
          xml.SendMessageBatchResultEntry do
            xml.Id msg_id
            xml.MessageId message.id
            xml.MD5OfMessageBody message.md5
          end
        end
      end
    end


    def change_message_visibility(name, params)
    end

    def change_message_visibility_batch(name, params)
    end

    # Fake actions

    def reset
      queues.reset
    end

    def expire
      queues.expire
    end

    private

    def respond(*args, &block)
      responder.call(*args, &block)
    end

    def url_for(id)
      "http://#{host}:#{port}/#{id}"
    end

  end
end
