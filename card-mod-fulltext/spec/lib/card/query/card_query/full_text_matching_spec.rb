RSpec.describe Card::Query::CardQuery::FullTextMatching do
  subject do
    Card::Query.run @query.reverse_merge(return: :name, sort: :name)
  end

  describe "fulltext_match: value" do
    it "matches on search_content" do
      @query = { fulltext_match: "Alphabet", type: "Company" }
      is_expected.to eq(["Google LLC"])
    end

    it "doesn't allow word fragments" do
      @query = { fulltext_match: "gle i", type: "Company" }
      is_expected.to eq([])
    end

    it "switches to sql regexp if preceeded by a ~" do
      @query = { fulltext_match: "~ gle i", type: "Company" }
      is_expected.to eq(["Google Inc."])
    end
  end

  describe "sort: relevance" do
    it "sorts by relevance" do
      @query = { fulltext_match: "sdg", sort: "relevance" }
      is_expected.to eq(["Programs+SDGs Research", "homepage featured answers"])
    end
  end
end
