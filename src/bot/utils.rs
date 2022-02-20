use anyhow::Result;

pub fn unescape(s: &str) -> Result<String> {
    Ok(serde_json::from_str(&format!(r#""{}""#, s))?)
}

pub async fn capture_redir(url: &str) -> Result<String> {
    Ok(reqwest::Client::new()
        .get(url)
        .send()
        .await?
        .url()
        .as_str()
        .into())
}

pub fn urlencode(s: &str) -> String {
    url::form_urlencoded::Serializer::new(String::new())
        .append_key_only(s)
        .finish()
}

mod tests {
    #![cfg(test)]
    #![allow(clippy::enum_glob_use)]

    use indoc::indoc;
    use pretty_assertions::assert_eq;

    use super::*;

    #[test]
    fn test_urlencode() {
        let original = "春眠暁を覚えず";
        let expected = "%E6%98%A5%E7%9C%A0%E6%9A%81%E3%82%92%E8%A6%9A%E3%81%88%E3%81%9A";
        assert_eq!(urlencode(original), expected);
    }

    #[tokio::test]
    async fn test_capture_redir() -> Result<()> {
        let url = "https://duck.com";
        let got = capture_redir(url).await?;
        assert_eq!("https://duckduckgo.com/", got);
        Ok(())
    }

    #[test]
    fn test_unescape() {
        let escaped = "== English ==\\n\\n\\n=== Etymology 1 ===\\nAttested since the 16th century; borrowed from Scots wow.\\n\\n\\n==== Pronunciation ====\\nenPR: wou, IPA(key): /wa\\u028a\\u032f/\\n\\nRhymes: -a\\u028a";
        let expected = indoc! {"
            == English ==


            === Etymology 1 ===
            Attested since the 16th century; borrowed from Scots wow.

            
            ==== Pronunciation ====
            enPR: wou, IPA(key): /waʊ̯/
            
            Rhymes: -aʊ"
        };
        assert_eq!(unescape(escaped).unwrap(), expected);
    }
}
