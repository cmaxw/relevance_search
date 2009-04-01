class << ActiveRecord::Base
  def relevance_search_attributes(attrs)
    @relevance_search_attributes = {}
  end

  def relevance_search(term)
    if @relevance_search_attributes.nil?
      search_attributes = self.new.attribute_names
    else
      search_attributes = @relevance_search_attributes
    end
    db_conf = YAML.load_file(File.join(File.dirname(__FILE__), '/../../../../config/database.yml'))[ENV['RAILS_ENV']]
    temp_db = Mysql.real_connect(db_conf["host"], db_conf["username"], db_conf["password"], db_conf["database"])
    temp_db.query "CREATE TEMPORARY TABLE temp_table (id int);"
    search_attributes.each do |attr|
      temp_db.query "INSERT INTO temp_table (id) SELECT id FROM #{table_name} WHERE #{attr} like '%#{term}%';"
    end
    query_results = temp_db.query("SELECT id FROM temp_table GROUP BY id ORDER BY COUNT(*) DESC, id ASC;")
    results = []
    query_results.each {|row| results << find_by_id(row[0])}
    results
  end
end

class ActiveRecord::Base
  def relevance(term)
    if @relevance_search_attributes.nil?
      search_attributes = self.new.attribute_names
    else
      search_attributes = @relevance_search_attributes
    end
    rel = 0
    search_attributes.each {|attr| rel += 1 if eval("#{attr}.to_s.include?(term)")}
  end
end

