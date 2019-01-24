describe Jets::Controller::Response do
  let(:resp) { Jets::Controller::Response.new }

  context "resp" do
    it "headers" do
      expect(resp.headers).to eq({})
      resp.headers["Set-Cookie"] = "foo=bar"
      resp.set_header("AnotherHeader", "MyValue")
      expect(resp.headers).to eq({"Set-Cookie" => "foo=bar", "AnotherHeader" => "MyValue"})
    end

    it "cookies" do
      resp.set_cookie(:favorite_food, "chocolate cookie")
      resp.set_cookie(:favorite_color, "yellow")
      resp.delete_cookie(:favorite_food)
      expect(resp.headers).to eq({"Set-Cookie"=>
        "favorite_color=yellow\n" +
        "favorite_food=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"})
    end
  end
end
