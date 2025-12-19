#!/bin/bash

message=admin
branch=main

git status

git add *

git commit -m "$message"

git push origin $branch
