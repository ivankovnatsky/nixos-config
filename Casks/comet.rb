cask "comet" do
  version "141.0.7390.23964"
  sha256 :no_check

  url "https://www.perplexity.ai/rest/browser/binaries/141.0.7390.23964/comet_latest.dmg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=9d06dad57704bf499ceb71a8730b22e4%2F20251023%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20251023T140226Z&X-Amz-Expires=300&X-Amz-Signature=20e487bf4838e1c6ad8721dc43fa0a94fc8186df537f4d4a14436c6f7f31b242&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject"
  name "Comet"
  desc "Comet browser by Perplexity AI"
  homepage "https://www.perplexity.ai"

  app "Comet.app"
end
