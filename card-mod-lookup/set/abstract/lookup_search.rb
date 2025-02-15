def search args={}
  return_type = args.delete :return
  query = args.delete(:query) || query(args)
  run_query_returning query, return_type
end

def run_query_returning query, return_type
  case return_type
  when :name  then query.run.map(&:name)
  when :count then query.count
  else             query.run
  end
end

def query_class
  raise Error::ServerError, "query_class required!"
end

def query paging={}
  query_class.new query_hash, {}, paging
end

def query_hash
  {}
end

def count
  query.count
end

format do
  delegate :query_class, to: :card

  def search_with_params
    @search_with_params ||= card.search query: query
  end

  def count_with_params
    @count_with_params ||= card.search query: count_query, return: :count
  end

  def query
    query_class.new query_hash, sort_hash, paging_params
  end

  def count_query
    query_class.new query_hash
  end

  def query_hash
    (filter_hash || {}).merge card.query_hash
  end

  def default_filter_hash
    card.query_hash
  end

  def sort_hash
    { sort_by.to_sym => sort_dir }
  end

  def sort_dir
    return unless sort_by
    @sort_dir ||= safe_sql_param("sort_dir") || default_sort_dir(sort_by)
  end

  def default_sort_dir sort_by
    if default_desc_sort_dir.include? sort_by.to_sym
      :desc
    else
      :asc
    end
  end

  def default_desc_sort_dir
    []
  end

  def sort_by
    @sort_by ||= sort_by_from_param || default_sort_option
  end

  def default_sort_option
    # override
  end

  def sort_by_from_param
    # :sort is DEPRECATED
    safe_sql_param(:sort_by)&.to_sym || safe_sql_param(:sort)&.to_sym
  end

  # not a CQL search
  def filter_cql
    {}
  end
end
