require "net/https"
require "yaml"
require "uri"
require "json"


def json_get(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)
  JSON.parse response.body
end

def username
  YAML::load(open("config.yaml").read)["username"]
end

def get_user_repos
  json_get "https://api.github.com/users/#{username}/repos"
end

def find_forks(repos)
  repos.find_all {|repo| repo["fork"]}
end

def find_parents(repos)
  parents = []
  repos.each do |repo|
    url = repo["url"]
    json = json_get url
    parent = json["parent"]["url"]
    parents << parent
  end

  return parents
end

def find_my_pull_requests(repo_urls, username)
  results = []
  repo_urls.each do |url|
    url = url + "/pulls"
    json = json_get url
    json.each do |pr|
      if pr["user"]["login"] == username
        results << {:state => pr["state"], :url => pr["html_url"], :title => pr["title"]}
      end
    end

    url = url + "?state=closed"
    json = json_get url
    json.each do |pr|
      if pr["user"]["login"] == username
        state = nil

        if pr["state"] == "open"
          state = "open"
        elsif pr.has_key? "merged_at"
          state = "merged"
        else
          state = "closed"
        end

        results << {:state => state, :url => pr["html_url"], :title => pr["title"]}
      end
    end

  end

  return results

end

def pulls
  find_my_pull_requests(find_parents(find_forks(get_user_repos)), username)
end

puts pulls.to_json
