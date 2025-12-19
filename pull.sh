#!/bin/bash

message=admin
branch=main

git switch $branch

git fetch origin

git pull origin $branch

