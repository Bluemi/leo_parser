#!/usr/bin/python

from html.parser import HTMLParser
import sys
import requests

search_strings = ["section-subst", "section-adjadv", "section-verb"]

# The Parser
class LeoParser(HTMLParser):
    def __init__(self):
        self.in_block = False
        self.in_block_counter = 0
        self.started_newline = False;
        self.current_element = ["", ""]
        self.insert_index = 0
        self.result_list = []
        super().__init__()

    def handle_starttag(self, tag, attrs):
        if tag == "div":
            for a in attrs:
                for s in search_strings:
                    if a[0] == "id" and a[1] == s:
                        self.in_block = True;
                        self.in_block_counter = 0
                        break;

        if self.in_block:
            self.in_block_counter += 1
            if tag == "tr": # in newline
                self.insert_index = 0
                self.started_newline = True;
                self.result_list.append(self.current_element)
                self.current_element = ["", ""]

        if tag == "td" and self.in_block:
            for a in attrs:
                if a[0] == "data-dz-attr" and a[1] == "relink":
                    if not self.started_newline:
                        #print("#", end="")
                        self.insert_index += 1
                    self.started_newline = False
                    break

    def handle_endtag(self, tag):
        self.in_block_counter -= 1
        if self.in_block_counter <= 0:
            self.in_block = False;


    def handle_data(self, data):
        if self.in_block:
            if (data.strip() != "") and (self.insert_index < 2):
                self.current_element[self.insert_index] += (" " + data.strip())
                #print(data.strip() + " ", end="")

if sys.argv[1] is None:
    print("usage: leo <searchword>")
    sys.exit(0)

parser = LeoParser();

def print_results(result_list):
    max_first = 0
    for i in result_list:
        if len(i[0]) > max_first:
            max_first = len(i[0])

    max_last = 0
    for i in result_list:
        if len(i[1]) > max_last:
            max_last = len(i[1])

    for i in result_list:
        if i[0].strip() == "":
            continue
        if i[1].strip() == "":
            print("\n" + i[0].strip() + "\n")
            continue
        print("   " + i[0].strip().ljust(max_first) + " - " + i[1].strip().ljust(max_last))


if len(sys.argv) < 2:
    print("usage: leo <searchword>")
    sys.exit(0)

path = 'https://dict.leo.org/englisch-deutsch/' + sys.argv[1]
response = requests.get(path)
parser.feed(response.text)

print_results(parser.result_list)

print("\n")
