require 'tempfile'

module SignHost
  class ApiClient
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def post_transaction(payload)
      RestClient.post(new_transaction_url, payload.to_json, auth_headers.merge(content_type: 'application/json', accept: 'application/json')) { |response, request, result, &block|
        case response.code
        when 200
          JSON.parse(response.body)
        else
          response.return!(request, result, &block)
        end
      }
    end

    def put_file(file_id, file)
      RestClient.put(upload_file_url(file_id), file, auth_headers.merge(multipart: true, content_type: 'application/pdf')) { |response, request, result, &block |
        case response.code
        when 200
          true
        else
          response.return!(request, result, &block)
        end
      }
    end

    def add_file(transaction_id, file_id, file)
      RestClient.put(add_file_url(transaction_id, file_id), file, auth_headers.merge(multipart: true, content_type: 'application/pdf')) { |response, request, result, &block |
        case response.code
        when 200
          true
        else
          response.return!(request, result, &block)
        end
      }
    end

    def start_transaction(transaction_id)
      RestClient.put(start_transaction_url(transaction_id), nil, auth_headers.merge(content_type: 'application/json', accept: 'application/json')) { |response, request, result, &block|
        case response.code
        when 200
          JSON.parse(response.body)
        else
          response.return!(request, result, &block)
        end
      }
    end

    def get_transaction(transaction_id)
      RestClient.get(transaction_url(transaction_id), auth_headers.merge(content_type: 'application/json', accept: 'application/json')) { |response, request, result, &block |
        case response.code
        when 200
          JSON.parse(response.body)
        else
          response.return!(request, result, &block)
        end
      }
    end

    def delete_transaction(transaction_id)
      RestClient.delete(transaction_url(transaction_id), auth_headers.merge(content_type: 'application/json', accept: 'application/json')) do |response, request, result, &block |
        case response.code
        when 200
          JSON.parse(response.body)
        else
          response.return!(request, result, &block)
        end
      end
    end

    def get_signed_document(file_id, file_options={})
      RestClient.get(signed_document_url(file_id), auth_headers) { |response, request, result, &block |
        case response.code
        when 200
          file = Tempfile.new(['signed-document', '.pdf'], file_options)
          file.write response.body
          file.path
        else
          response.return!(request, result, &block)
        end
      }
    end

    def get_receipt(transaction_id)
      RestClient.get(receipt_url(transaction_id), auth_headers) { |response, request, result, &block |
        case response.code
        when 200
          file = Tempfile.new(['receipt', '.pdf'])
          file.write response.body
          file.path
        else
          response.return!(request, result, &block)
        end
      }
    end

    private

    def new_transaction_url
      api_url + "transaction"
    end

    def upload_file_url(file_id)
      api_url + "file/" + file_id
    end

    def add_file_url(transaction_id, file_id)
      api_url + "transaction/" + transaction_id + "/file/" + file_id
    end

    def start_transaction_url(transaction_id)
      api_url + "transaction/" + transaction_id + "/start"
    end

    def transaction_url(transaction_id)
      api_url + "transaction/" + transaction_id
    end

    def signed_document_url(file_id)
      api_url + "file/document/#{file_id}"
    end

    def receipt_url(transaction_id)
      api_url + "file/receipt/#{transaction_id}"
    end

    def api_url
      "https://api.signhost.com/api/"
    end

    def auth_headers
      {
        authorization: "APIKey #{configuration.api_key}",
        application: "APPKey #{configuration.application_key}"
      }
    end

  end
end
