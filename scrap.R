library(tidyverse)
library(jsonlite)
library(rjson)

raw_json_schedule <- fromJSON(file = "data/PositConf2023_Schedule.json")

# what if I use jsonlite? test_schedule <- jsonlite::read_json("PositConf2023_Schedule.json")
# gets me same data object, I think? but it's larger? fromJSON() simplifies

# Ok, so this is the basic structure to get to something
raw_json_schedule[[1]]$items[[1]]$title

# inside of raw_json_schedule it goes from [[1]] to [[14]]
# 
# inside each one, there is a DIFFERENT number of items
# c(1, 1, 21, 8, 12, 8, 8, 1, 1, 12, 8, 11, 8, 8)
# 
# that means the last one is raw_json_schedule[[14]]$items[[8]]$title

# this can be done using purrr::pluck()

raw_json_schedule %>% purrr::pluck(1, "items", 1, "title")


# create a schedule variable that's a tibble from the json lists

schedule <- tibble(section = raw_json_schedule) |> 
                  unnest_wider(section) |> 
                  as.data.frame()

# create some 

# schedule |> hoist(section, 
#                   item = "items")


# and a data frame version





# I need a function that, given the number and item number will go get
# all the stuff we want

get_talk_data <- function(sectionNum, itemNum) {
  
  talk_type <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "type") 
  
  talk_title <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "title") 
  
  talk_date <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "dateFormatted") 
  
  talk_start_time <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "startTimeFormatted")
  
  talk_end_time <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "endTimeFormatted")
  
  talk_location <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "room")
  
  talk_speaker <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "participants", 1, "fullName")
  
  # get abstract, but drop all the html tags that get picked up
  talk_abstract <- gsub("<.*?>", "", raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "abstract"))
  
  # check for multiple speakers! Some talks have two and one has three
  
  # check for the one with 3 first, then 2 only if it didn't have a 3rd
  if (!is.null(raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 3, "fullName"))) {
    talk_speaker <- paste0(raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 1, "fullName"),
             ", ",
             raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 2, "fullName"),
             ", & ",
             raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 3, "fullName"))
  } else if (!is.null(raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 2, "fullName"))) {
      talk_speaker <- paste0(raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 1, "fullName"),
             " & ",
             raw_json_schedule %>% purrr::pluck(sectionNum, "items", itemNum, "participants", 2, "fullName"))
    }
  
  
  
  # output a dataframe
  data.frame(type = talk_type, 
             title = talk_title, 
             date = talk_date,
             start_time = talk_start_time,
             end_time = talk_end_time,
             room = talk_location,
             speaker = talk_speaker,
             abstract = talk_abstract)
}

# create an empty df to fill with talk info

talk_df <- data.frame(matrix(ncol = 8, nrow = 0))

colnames(talk_df) <- c('type', 'title', 'date', 'start_time', 'end_time', 'room', 'speaker', 'abstract')

# loop through the talks and grab stuff

# for each section of the json item
for (i in 1:nrow(schedule)) {
  # for each talk in the section
  for (j in 1:schedule[i, "numItems"]) {
    
    talk_df <- rbind(talk_df, get_talk_data(i, j))
    
  }
  
}

# did that work?
str(talk_df) 



###############################################################################

# get OTHER stuff (not talks) Need to edit all the stuff below here
raw_json_schedule_nontalks <- fromJSON(file = "data/PositConf2023_Schedule_nontalks.json")


# create a schedule variable that's a tibble from the json lists

nontalks_schedule <- tibble(section = raw_json_schedule_nontalks) |> 
  unnest_wider(section) |> 
  as.data.frame()

get_nontalk_data <- function(sectionNum, itemNum) {
  
  talk_type <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "type") 
  
  talk_title <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "title") 
  
  talk_date <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "dateFormatted") 
  
  talk_start_time <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "startTimeFormatted")
  
  talk_end_time <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "endTimeFormatted")
  
  talk_location <- raw_json_schedule_nontalks %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "room")
  
  # get abstract, but drop all the html tags that get picked up
  talk_abstract <- gsub("<.*?>", "", raw_json_schedule_nontalks %>% 
                          purrr::pluck(sectionNum, "items", itemNum, "abstract"))
  
  # output a dataframe
  data.frame(type = talk_type, 
             title = talk_title, 
             date = talk_date,
             start_time = talk_start_time,
             end_time = talk_end_time,
             room = talk_location,
             abstract = talk_abstract)
}

# create an empty df to fill with talk info

nontalk_df <- data.frame(matrix(ncol = 7, nrow = 0))

colnames(nontalk_df) <- c('type', 'title', 'date', 'start_time', 'end_time', 'room', 'abstract')

# loop through the talks and grab stuff

# for each section of the json item
for (i in 1:nrow(nontalks_schedule)) {
  # for each talk in the section
  for (j in 1:nontalks_schedule[i, "numItems"]) {
    
    nontalk_df <- rbind(nontalk_df, get_nontalk_data(i, j))
    
      }
  
}

# did that work?
str(nontalk_df) 
