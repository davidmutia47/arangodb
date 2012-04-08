require 'rspec'
require './avocadodb.rb'

describe AvocadoDB do
  prefix = "rest_read-document"

  context "reading a document:" do

################################################################################
## error handling
################################################################################

    context "error handling:" do
      before do
	@cn = "UnitTestsCollectionBasics"
	@cid = AvocadoDB.create_collection(@cn)
      end

      after do
	AvocadoDB.drop_collection(@cn)
      end

      it "returns an error if document handle is corrupted" do
	cmd = "/document/123456"
        doc = AvocadoDB.log_get("#{prefix}-bad-handle", cmd)

	doc.code.should eq(400)
	doc.parsed_response['error'].should eq(true)
	doc.parsed_response['errorNum'].should eq(601)
	doc.parsed_response['code'].should eq(400)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if document handle is corrupted with empty cid" do
	cmd = "/document//123456"
        doc = AvocadoDB.log_get("#{prefix}-bad-handle2", cmd)

	doc.code.should eq(400)
	doc.parsed_response['error'].should eq(true)
	doc.parsed_response['errorNum'].should eq(600)
	doc.parsed_response['code'].should eq(400)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if collection identifier is unknown" do
	cmd = "/document/123456/234567"
        doc = AvocadoDB.log_get("#{prefix}-unknown-cid", cmd)

	doc.code.should eq(404)
	doc.parsed_response['error'].should eq(true)
	doc.parsed_response['errorNum'].should eq(1203)
	doc.parsed_response['code'].should eq(404)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if document handle is unknown" do
	cmd = "/document/#{@cid}/234567"
        doc = AvocadoDB.log_get("#{prefix}-unknown-handle", cmd)

	doc.code.should eq(404)
	doc.parsed_response['error'].should eq(true)
	doc.parsed_response['errorNum'].should eq(1202)
	doc.parsed_response['code'].should eq(404)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	AvocadoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## reading documents
################################################################################

    context "reading a document:" do
      before do
	@cn = "UnitTestsCollectionBasics"
	@cid = AvocadoDB.create_collection(@cn)
      end

      after do
	AvocadoDB.drop_collection(@cn)
      end

      it "create a document and read it" do
	cmd = "/document?collection=#{@cid}"
	body = "{ \"Hallo\" : \"World\" }"
	doc = AvocadoDB.post(cmd, :body => body)

	doc.code.should eq(201)

	location = doc.headers['location']
	location.should be_kind_of(String)

	did = doc.parsed_response['_id']
	rev = doc.parsed_response['_rev']

	# get document
	cmd = "/document/#{did}"
        doc = AvocadoDB.log_get("#{prefix}", cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	did2 = doc.parsed_response['_id']
	did2.should be_kind_of(String)
	did2.should eq(did)
	
	rev2 = doc.parsed_response['_rev']
	rev2.should be_kind_of(Integer)
	rev2.should eq(rev)

	etag = doc.headers['etag']
	etag.should be_kind_of(String)

	etag.should eq("\"#{rev}\"")

	AvocadoDB.delete(location)

	AvocadoDB.size_collection(@cid).should eq(0)
      end

      it "create a document and read it, use if-none-match" do
	cmd = "/document?collection=#{@cid}"
	body = "{ \"Hallo\" : \"World\" }"
	doc = AvocadoDB.post(cmd, :body => body)

	doc.code.should eq(201)

	location = doc.headers['location']
	location.should be_kind_of(String)

	did = doc.parsed_response['_id']
	rev = doc.parsed_response['_rev']

	# get document, if-none-match with same rev
	cmd = "/document/#{did}"
	hdr = { "if-none-match" => "\"#{rev}\"" }
        doc = AvocadoDB.log_get("#{prefix}-if-none-match", cmd, :headers => hdr)

	doc.code.should eq(304)

	etag = doc.headers['etag']
	etag.should be_kind_of(String)

	etag.should eq("\"#{rev}\"")

	# get document, if-none-match with different rev
	cmd = "/document/#{did}"
	hdr = { "if-none-match" => "\"#{rev-1}\"" }
        doc = AvocadoDB.log_get("#{prefix}-if-none-match-other", cmd, :headers => hdr)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	etag = doc.headers['etag']
	etag.should be_kind_of(String)

	etag.should eq("\"#{rev}\"")

	did2 = doc.parsed_response['_id']
	did2.should be_kind_of(String)
	did2.should eq(did)
	
	rev2 = doc.parsed_response['_rev']
	rev2.should be_kind_of(Integer)
	rev2.should eq(rev)

	etag = doc.headers['etag']
	etag.should be_kind_of(String)

	etag.should eq("\"#{rev}\"")

	AvocadoDB.delete(location)

	AvocadoDB.size_collection(@cid).should eq(0)
      end

      it "create a document and read it, use if-match" do
	cmd = "/document?collection=#{@cid}"
	body = "{ \"Hallo\" : \"World\" }"
	doc = AvocadoDB.post(cmd, :body => body)

	doc.code.should eq(201)

	location = doc.headers['location']
	location.should be_kind_of(String)

	did = doc.parsed_response['_id']
	rev = doc.parsed_response['_rev']

	# get document, if-match with same rev
	cmd = "/document/#{did}"
	hdr = { "if-match" => "\"#{rev}\"" }
        doc = AvocadoDB.log_get("#{prefix}-if-match", cmd, :headers => hdr)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	did2 = doc.parsed_response['_id']
	did2.should be_kind_of(String)
	did2.should eq(did)
	
	rev2 = doc.parsed_response['_rev']
	rev2.should be_kind_of(Integer)
	rev2.should eq(rev)

	etag = doc.headers['etag']
	etag.should be_kind_of(String)

	etag.should eq("\"#{rev}\"")

	# get document, if-match with different rev
	cmd = "/document/#{did}"
	hdr = { "if-match" => "\"#{rev-1}\"" }
        doc = AvocadoDB.log_get("#{prefix}-if-match-other", cmd, :headers => hdr)

	doc.code.should eq(412)

	did2 = doc.parsed_response['_id']
	did2.should be_kind_of(String)
	did2.should eq(did)
	
	rev2 = doc.parsed_response['_rev']
	rev2.should be_kind_of(Integer)
	rev2.should eq(rev)

	AvocadoDB.delete(location)

	AvocadoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## reading all documents
################################################################################

    context "reading all documents:" do
      before do
	@cn = "UnitTestsCollectionAll"
	@cid = AvocadoDB.create_collection(@cn)
      end

      after do
	AvocadoDB.drop_collection(@cn)
      end

      it "get all documents of an empty collection" do
	cmd = "/document?collection=#{@cid}"

	# get documents
	cmd = "/document?collection=#{@cid}"
        doc = AvocadoDB.log_get("#{prefix}-all-0", cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	documents = doc.parsed_response['documents']
	documents.should be_kind_of(Array)
	documents.length.should eq(0)

	AvocadoDB.size_collection(@cid).should eq(0)
      end

      it "create three documents and read them using the collection identifier" do
	cmd = "/document?collection=#{@cid}"

	location = []

	for i in [ 1, 2, 3 ]
	  body = "{ \"Hallo\" : \"World-#{i}\" }"
	  doc = AvocadoDB.post(cmd, :body => body)

	  doc.code.should eq(201)

	  location.push(doc.headers['location'])
	end

	# get document
	cmd = "/document?collection=#{@cid}"
        doc = AvocadoDB.log_get("#{prefix}-all", cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	documents = doc.parsed_response['documents']
	documents.should be_kind_of(Array)
	documents.length.should eq(3)

	for l in location
	  AvocadoDB.delete(l)
	end

	AvocadoDB.size_collection(@cid).should eq(0)
      end

      it "create three documents and read them using the collection name" do
	cmd = "/document?collection=#{@cn}"

	location = []

	for i in [ 1, 2, 3 ]
	  body = "{ \"Hallo\" : \"World-#{i}\" }"
	  doc = AvocadoDB.post(cmd, :body => body)

	  doc.code.should eq(201)

	  location.push(doc.headers['location'])
	end

	# get document
	cmd = "/document?collection=#{@cn}"
        doc = AvocadoDB.log_get("#{prefix}-all-name", cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	documents = doc.parsed_response['documents']
	documents.should be_kind_of(Array)
	documents.length.should eq(3)

	for l in location
	  AvocadoDB.delete(l)
	end

	AvocadoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## checking document
################################################################################

    context "checking a document:" do
      before do
	@cn = "UnitTestsCollectionBasics"
	@cid = AvocadoDB.create_collection(@cn)
      end

      after do
	AvocadoDB.drop_collection(@cn)
      end

      it "create a document and read it" do
	cmd = "/document?collection=#{@cid}"
	body = "{ \"Hallo\" : \"World\" }"
	doc = AvocadoDB.post(cmd, :body => body)

	doc.code.should eq(201)

	location = doc.headers['location']
	location.should be_kind_of(String)

	# get document
	cmd = location
        doc = AvocadoDB.log_get("#{prefix}-head", cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	content_length = doc.headers['content-length']

	# get the document head
        doc = AvocadoDB.head(cmd)

	doc.code.should eq(200)
	doc.headers['content-type'].should eq("application/json; charset=utf-8")

	doc.headers['content-length'].should eq(content_length)
	doc.body.should eq(nil)

	AvocadoDB.delete(location)

	AvocadoDB.size_collection(@cid).should eq(0)
      end
    end

  end
end
