import os

def file_content(filepath):
    """ Fetches and formats file's content to perform the required operation.
    """

    filelines = tuple(open(filepath, 'r'))

    comment_indexes = []
    comments = []

    for line in enumerate(filelines):
        if "@startBlockCode" in line[1]:
            _start = line[0]
        if "@endBlockCode" in line[1]:
            _end = line[0] + 1
            comment_indexes.append([_start, _end])

    for index in comment_indexes:
        comments.append(filelines[index[0]: index[1]])

    return comments


def fetch_comments(dirpath):
    """ Fetches comments from files and writes to a file in required format.
    """

    comments_filename = "allComments.txt"
    fh = open(comments_filename, "w")

    for root, directories, files in os.walk(dirpath):
        for filename in files:
            filepath = os.path.join(root, filename)
            file_comments = file_content(filepath)
            for comment in file_comments:
                fh.write("\n<!-- %s -->\n" % filename)
                for _com in comment:
                    _text = _com.replace("/", "")
                    _text = _text.strip()
                    if _text:
                        if ("@startBlockCode" in _text) or \
                           ("@endBlockCode" in _text):
                            fh.write("<!-- %s -->\n" % _text)
                        else:
                            fh.write("%s\n" % _text)

    fh.close()

if __name__ == "__main__":
    dirpath = "/Users/Thomas/code/ArangoDB"
    fetch_comments(dirpath)
