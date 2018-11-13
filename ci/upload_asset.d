import std.file;
import std.format;
import std.getopt;
import std.json;
import std.net.curl;
import std.path;
import std.regex;
import std.stdio;

private immutable apiEndpoint = "https://api.github.com";

int main(string[] args)
{
    string token;
    string file;
    string owner;
    string repository;
    string tag;
    ubyte[] data;

    foreach (chunk; stdin.byChunk(4096))
    {
        data ~= chunk;
    }

    getopt(args, "token", &token, "file", &file, "owner", &owner, "repo",
            &repository, "tag", &tag);
    const releaseUrl = format!"%s/repos/%s/%s/releases/tags/%s"(apiEndpoint, owner, repository, tag);
    const release = parseJSON(get(releaseUrl));
    const uploadUrl = release["upload_url"].str.replaceAll(regex(`\{[^\}]*\}`,
            "g"), "") ~ "?name=" ~ baseName(file);

    auto request = HTTP(uploadUrl);
    request.addRequestHeader("Authorization", "token " ~ token);
    request.setPostData(data, "application/zip");
    request.onReceive = (bytes) {
        stdout.write(cast(string) bytes);
        return bytes.length;
    };
    request.perform();

    return 0;
}
