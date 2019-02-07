
meta_source_dir = 'src/meta'

desc "task to promote artifacts to release"
task :promote, [:experimental_bucket_url, :stable_bucket_url, :update_bucket_url] do |t, args|
  experimental_bucket_url = args[:experimental_bucket_url]
  raise "Please specify experimental bucket url" unless experimental_bucket_url

  stable_bucket_url = args[:stable_bucket_url]
  raise "Please specify stable bucket url" unless stable_bucket_url

  update_bucket_url = args[:update_bucket_url]
  raise "Please specify update bucket url" unless update_bucket_url


  go_full_version = JSON.parse(File.read("#{meta_source_dir}/version.json"))['go_full_version']

  sh("aws s3 sync s3://#{experimental_bucket_url}/bianries/#{go_full_version} s3://#{stable_bucket_url}/binaries/#{go_full_version} --acl public-read --cache-control 'max-age=31536000'")

  # sync adds ons

  # create repos
  sh("./create-repositories")

  sh("AWS_PROFILE=update aws s3 cp s3://#{update_bucket_url}/channels/supported/latest.json s3://#{update_bucket_url}/channels/supported/latest.previous.json --cache-control 'max-age=600' --acl public-read")

  sh("aws s3 cp s3://#{experimental_bucket_url}/binaries/#{go_full_version}/latest.json /tmp/latest.json")

  sh("AWS_PROFILE=update aws s3 cp /tmp/latest.json s3://#{update_bucket_url}/channels/supported/latest.json --cache-control 'max-age=600' --acl public-read")
  sh("AWS_PROFILE=update aws s3 cp /tmp/latest.json s3://#{update_bucket_url}/channels/supported/latest-#{go_full_version}.json --cache-control 'max-age=600' --acl public-read")
  sh("rm /tmp/latest.json")
end

task :default, [:experimental_bucket_url, :stable_bucket_url, :update_bucket_url] => [:promote]
