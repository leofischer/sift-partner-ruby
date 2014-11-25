require 'uri'
require 'json'
require 'httparty'
require 'sift' # we use Response

module SiftPartner

  # Ruby bindings for Sift Science's Partner API.
  # For background and examples on how to use the Partner API with this client
  # please refer to https://siftscience.com/resources/references/partner-ruby.html
  class Client
    API_ENDPOINT = "https://partner.siftscience.com/v3"
    API_TIMEOUT = 2

    #
    # Constructor
    # == Parameters:
    # api_key
    #   The api_key of the partner
    #   (which may be found in the api_keys section of the console)
    # id
    #   The account id of the partner
    #   (which may be found in the settings page of the console)
    def initialize(api_key = Sift.api_key, id = Sift.account_id)
      raise(RuntimeError, "api_key must be a non-empty string") if (!api_key.is_a? String) || api_key.empty?
      raise(RuntimeError, "partner must be a non-empty string") if (!id.is_a? String) || id.empty?
      @api_key = api_key
      @id = id
    end

    # Creates a new merchant account under the given partner.
    # == Parameters:
    # site_url
    #    the url of the merchant site
    # site_email
    #    an email address for the merchant
    # analyst_email
    #    an email address which will be used to log in at the Sift Console
    # password
    #    password (at least 10 chars) to be used to sign into the Console
    #
    # When successful, returns a including the new account id and credentials.
    # When an error occurs, returns nil.
    def new_account(site_url, site_email, analyst_email, password)

      raise(RuntimeError, "site url must be a non-empty string") if (!site_url.is_a? String) || site_url.empty?
      raise(RuntimeError, "site email must be a non-empty string") if (!site_email.is_a? String) || site_email.empty?
      raise(RuntimeError, "analyst email must be a non-empty string") if (!analyst_email.is_a? String) || analyst_email.empty?
      raise(RuntimeError, "password must be a non-empty string") if (!password.is_a? String) || password.empty?

      reqBody = {:site_url => site_url, :site_email => site_email,
                 :analyst_email => analyst_email, :password => password}
      begin
        http_post(accounts_url(), reqBody)
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end

    end

    # Gets a listing of the ids and keys for all merchant accounts that have
    # been created by this partner.
    #
    # When successful, returns a hash including the key :data, which is an
    # array of account descriptions. (Each element has the same structure as a
    # single response from new_account).
    def get_accounts()
      http_get(accounts_url)
    end

    # Updates the configuration which controls http notifications for all merchant
    # accounts under this partner.
    #
    # == Parameters
    # notification_url
    #  A String which determines the url to which
    #  the POST notifications go,containing the string '%s' exactly
    #  once.  This allows the url to be used as a template, into which a
    #  merchant account id can be substituted.
    #
    # notification_threshold
    #  A floating point number between 0.0 and
    #  1.0, determining the score threshold at which to push
    #  notifications.  It represents the Sift Score/100
    #
    # DEPRECIATED USE:
    #   notification_url may also be a Hash, with keys
    #   http_notification_url and http_notification_threshold.
    #   The value of the notification_url will be a url containing the
    #   string '%s' exactly once.  This allows the url to be used as a
    #   template, into which a merchant account id can be substituted.
    #   The  notification threshold should be a floating point number
    #   between 0.0 and 1.0
    def update_notification_config(notification_url = nil, notification_threshold = nil)

      properties = {}
      
      # To support depreciated use
      if notification_url.is_a? Hash
        properties = notification_url
      else
        raise(RuntimeError, "notification url must be a non-empty string") if (!notification_url.is_a? String) || notification_url.empty?
        raise(RuntimeError, "notification threshold must be a float") if (!notification_threshold.is_a? Float)

        properties['http_notification_url'] = notification_url
        properties['http_notification_threshold'] = notification_threshold

      end

      http_put(notification_config_url(), properties)
    end

    private
      def accounts_url
        URI("#{API_ENDPOINT}/partners/#{@id}/accounts")
      end

      def user_agent
        "SiftScience/v#{API_VERSION} sift-partner-ruby/#{VERSION}"
      end

      def notification_config_url
        URI("#{API_ENDPOINT}/accounts/#{@id}/config")
      end

      def safe_json(http_response)
        response = Sift::Response.new(http_response.body, http_response.code)
        if !response.nil? and response.ok?
          response.json
        else
          puts "bad value in safeJson :"
          PP.pp(response)
        end
      end

      def prep_https(uri)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https
      end

      def http_get(uri)
        header =  {"Authorization" => "Basic #{@api_key}",
                    "User-Agent" => user_agent}

        http_response = HTTParty.get(uri, :headers =>header)
        safe_json(http_response)
      end

      def http_put(uri, bodyObj)
        header = {"Content-Type" => "application/json",
                  "Authorization" => "Basic #{@api_key}",
                  "User-Agent" => user_agent}

        http_response = HTTParty.put(uri, :body => bodyObj.to_json, :headers => header)
        safe_json(http_response)
      end

      def http_post(uri, bodyObj)
        header = {"Content-Type" => "application/json",
                  "Authorization" => "Basic #{@api_key}",
                  "User-Agent" => user_agent}
        http_response = HTTParty.post(uri, :body => bodyObj.to_json, :headers => header)
        safe_json(http_response)
      end
  end
end
