require "searchyll/version"
require "jekyll/hooks"
require "jekyll/plugin"
require "jekyll/generator"
require "searchyll/configuration"
require "searchyll/indexer"
require "nokogiri"

begin
  indexers = {}

  Jekyll::Hooks.register(:site, :pre_render) do |site|
    config = Searchyll::Configuration.new(site)
    indexers[site] = Searchyll::Indexer.new(config)
    indexers[site].start
  end

  Jekyll::Hooks.register :site, :post_render do |site|
    indexers[site].finish
  end

  Jekyll::Hooks.register :pages, :post_render do |post|
    # strip html
    nokogiri_doc = Nokogiri::HTML(post.output)
    # puts %(        indexing page #{post.url})
    if post.data.key?("date")
      # print(post.data)
      tDate = post["date"].iso8601.to_s
    else
      tDate = Time.now.iso8601.to_s
    end
    # puts Date.strptime(post["last_modified_at"].to_s, '%d-%b-%y').iso8601.to_s
    
    if post.data.key?("redirect_to")
      next
    end
    puts post.data
    indexer = indexers[post.site]
    indexer << post.data.merge({
      # id:     post.url,
      url: post.url,
      type: 'page',
      text: nokogiri_doc.xpath("//article//text()").to_s.gsub(/\s+/, " "),
      # text: nokogiri_doc.xpath("//main//text()").to_s.gsub(/\s+/, " "),
      # https://entsoe-tso.github.io/new-website/
      # date_published: tDate,
      "last_modified_at" => Date.strptime(post["last_modified_at"].to_s, '%d-%b-%y'),
      "categories" => 'page',
      base_url: "https://preview.entsoe.eu/", # https://hotelier-henry-25766.netlify.com/
      site: "entsoe.eu"
    })
    # puts post.last_modified_at
  end

  Jekyll::Hooks.register :posts, :post_render do |post|
    # strip html
    nokogiri_doc = Nokogiri::HTML(post.output)

    # puts %(        indexing document #{post.url})
    
    tDate = post.data["date"]

    # if post.data["date"]
    #   post.data.merge({"date": post.data["date"].utc.iso8601.to_s})
    # end
    # puts post.data.keys
    # puts post.id
    d = post.data.merge({
      # id: post.url,
      url: post.url,
      type: 'post',
      text: nokogiri_doc.xpath("//article//text()").to_s.gsub(/\s+/, " "),
      # text: nokogiri_doc.xpath("//main//text()").to_s.gsub(/\s+/, " "),
      date_published: tDate.iso8601.to_s,
      "last_modified_at" => Date.strptime(post.data["last_modified_at"].to_s, '%d-%b-%y'),
      base_url: "https://preview.entsoe.eu/", # https://hotelier-henry-25766.netlify.com/
      site: "entsoe.eu"
    })

    f = d.merge!({"date" => post.date.iso8601.to_s})

    # puts post.id

    indexer = indexers[post.site]
    indexer << f
  end

rescue => e
  puts e.message
end
