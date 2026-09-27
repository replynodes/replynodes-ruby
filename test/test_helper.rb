# frozen_string_literal: true

require "json"
require "socket"
require "minitest/autorun"
require "replynodes"

class FakeServer
  attr_reader :requests, :port

  def initialize(status: 200, body: {}, headers: {}, delay: 0)
    @status = status
    @body = body.is_a?(String) ? body : JSON.generate(body)
    @headers = { "Content-Type" => "application/json" }.merge(headers)
    @delay = delay
    @requests = []
    @running = true
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @thread = Thread.new { serve }
  end

  def url
    "http://127.0.0.1:#{port}"
  end

  def stop
    @running = false
    TCPSocket.new("127.0.0.1", port).close
  rescue Errno::ECONNREFUSED
    nil
  ensure
    @thread.join(2)
    @server.close unless @server.closed?
  end

  private

  def serve
    while @running
      begin
        socket = @server.accept
        request_line = socket.gets
        request_headers = {}
        while (line = socket.gets)
          break if line == "\r\n"

          key, value = line.split(":", 2)
          request_headers[key] = value.to_s.strip
        end
        @requests << { line: request_line.to_s, headers: request_headers }
        sleep @delay if @delay.positive?
        write_response(socket) if socket
        socket.close
      rescue IOError, Errno::EBADF, Errno::ECONNRESET
        break
      end
    end
  end

  def write_response(socket)
    status_text = @status == 200 ? "OK" : "Error"
    response_headers = @headers.merge("Content-Length" => @body.bytesize, "Connection" => "close")
    socket.write("HTTP/1.1 #{@status} #{status_text}\r\n")
    response_headers.each { |key, value| socket.write("#{key}: #{value}\r\n") }
    socket.write("\r\n#{@body}")
  rescue IOError, Errno::EPIPE, Errno::ECONNRESET
    nil
  end
end
