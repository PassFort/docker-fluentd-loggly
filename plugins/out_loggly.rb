=begin

  Copyright (C) 2012 Patrik Antonsson

  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.

=end

class LogglyOutput < Fluent::Output
  Fluent::Plugin.register_output('loggly', self)
  config_param :loggly_url, :string, :default => nil

  def configure(conf)
    super
    $log.debug "Loggly url #{@loggly_url}"
  end

  def start
    super
    require 'net/http/persistent'
    @uri = @loggly_url
    @http = Net::HTTP::Persistent.new 'fluentd-plugin-loggly', :ENV
    @http.headers['Content-Type'] = 'application/json'
  end

  def shutdown
    super
  end

  def make_uri(tag)
      if tag
          URI "#{@uri}tag/#{tag}"
      else
          URI @uri
      end
  end

  def emit(tag, es, chain)
    chain.next
    es.each {|time,record|
      $log.debug "<record>"
      $log.debug record
      $log.debug "</record>"
      record_json = Yajl::Encoder.encode(record)
      new_tag = /passfort\.var\.log\.containers\.([a-z-]*)-\d+/.match(tag)
      uri = make_uri(new_tag[1])
      $log.debug "<record_json>"
      $log.debug record_json
      $log.debug "</record_json>"
      post = Net::HTTP::Post.new uri.path
      post.body = record_json
      begin
        response = @http.request uri, post
        $log.debug "HTTP Response code #{response.code}"
        $log.error response.body if response.code != "200"
      rescue
        $log.error "Error connecting to loggly verify the url #{@loggly_url}"
      end
    }
  end
end
