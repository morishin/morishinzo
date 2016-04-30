require 'sinatra'
require "sinatra/reloader" if development?

require 'digest/md5'
require './s3_uploader'

EXT_WHITELIST = %w(
  png
  gif
  jpg
).inject([]){ |m,x| m.push(x,x.upcase) }

error 403 do
  "Access forbidden\n"
end

post '/upload' do
  token = request.env['HTTP_AUTHORIZATION']
  return 403 unless token == 'Bearer ' + ENV['BEARER_TOKEN']

  id = params['id']
  image_file = params['imagedata'][:tempfile]
  hash = Digest::MD5.hexdigest(image_file.read)
  image_file.seek(IO::SEEK_SET)

  ext = params['ext'] || 'png'
  exit unless EXT_WHITELIST.include?(ext)

  fname = "#{hash}.#{ext}"
  s3key = "#{fname}"
  S3Uploader.put(s3key, image_file)

  status 200
  headers 'X-Gyazo-Id' => '000'
  body "https://#{ENV['AWS_S3_BUCKET']}/#{s3key}"
end
