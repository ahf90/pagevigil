import pytest
from main import find_object_path


@pytest.mark.parametrize("url", ["https://example.com", "https://example.com/foo/bar"])
def test_find_object_path(url):
    assert url.split("/")[1] in find_object_path(url, "chrome")
    assert find_object_path(url, "chrome") != find_object_path(url + "/foo/bar.html", "browser")
