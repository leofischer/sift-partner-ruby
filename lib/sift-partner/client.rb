require 'uri'
require 'json'
require 'net/http'
require 'sift' # we use Response

module SiftPartner

  class Client
    API_ENDPOINT = "https://api3.siftscience.com/v3"
    API_TIMEOUT = 2

    def initialize(api_key = Sift.api_key, id = Sift.account_id) 
      @api_key = api_key
      @id = id
    end

    # returns nil if there was an exception
    def new_account(site_url, site_email, analyst_email, password)
      reqBody = {:site_url => site_url, :site_email => site_email,
                 :analyst_email => analyst_email, :password => password}
      begin
        http_post(accounts_url(), reqBody)
      rescue Exception => e  
        puts e.message  
        puts e.backtrace.inspect  
      end

    end

    def get_accounts()
      http_get(accounts_url)
    end

    def update_notification_config(cfg)
      http_post()
    end

    private
      def accounts_url
        URI("#{API_ENDPOINT}/partners/#{@id}/accounts")
      end

      def notification_config_url 
        URI("#{API_ENDPOINT}/accounts/#{id}/config")
      end

      def safe_json(http_response)
        response = Sift::Response.new(http_response.body, http_response.code)
        if !response.nil? and response.ok?
          response.json
        else
          puts "bad value in safeJson : \n#{response}"
        end
      end

      def prep_https(uri)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https
      end

      def http_get(uri)
        header = {"Authorization" => "Basic #{@api_key}"}
        req = Net::HTTP::Get.new(uri.path, initheader = header)
        https = prep_https(uri)
        http_response = https.request req
        safe_json(http_response)
      end

      def http_post(uri, bodyObj)
        header = {"Content-Type" => "application/json", 
                  "Authorization" => "Basic #{@api_key}"}
        req = Net::HTTP::Post.new(uri.path, initheader = header)
        req.body = bodyObj.to_json
        https = prep_https(uri)
        http_response = https.request req
        safe_json(http_response)
      end
  end
end
