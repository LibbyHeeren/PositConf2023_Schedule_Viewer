library(tidyverse)
library(jsonlite)
library(rjson)

# Call the raw json object I saved from the posit api response tab
# containing only Keynotes, Talks, and Lightning Talks
raw_json_schedule <- fromJSON(file = "data/PositConf2023_Schedule_talks_9-14-11pm.json")

# Create a data frame from the json
schedule <- tibble(section = raw_json_schedule) |> 
unnest_wider(section) |> 
  as.data.frame()

# Create a function that, given the section number and item number, will go get
# all the stuff I want

get_talk_data <- function(sectionNum, itemNum) {
  
  talk_type <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "type") 
  
  talk_title <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "title") 
  
  talk_date <- raw_json_schedule %>% 
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "daySort") %>%
    ymd() %>%
    as.Date() %>% 
    format("%m/%d/%Y")
  
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
  
  
  
  # output a row of info as a data frame, which we will rbind later
  data.frame(type = talk_type, 
             title = talk_title, 
             date = talk_date,
             start_time = talk_start_time,
             end_time = talk_end_time,
             room = talk_location,
             speaker = talk_speaker,
             abstract = talk_abstract)
}

# create an empty data frame to fill with talk info

talk_df <- data.frame(matrix(ncol = 8, nrow = 0))

colnames(talk_df) <- c('type', 
                       'title', 
                       'date', 
                       'start_time', 
                       'end_time', 
                       'room', 
                       'speaker', 
                       'abstract')

# loop through the talks and grab stuff

# for each section of the json item
for (i in 1:nrow(schedule)) {
  # for each talk in the section
  for (j in 1:schedule[i, "numItems"]) {
    
    talk_df <- rbind(talk_df, get_talk_data(i, j))
    
  }
  
}


# Save the data frame as a csv file so it's easy to put into Notion if I want to
write_csv(talk_df, "output/PositConf2023_talks.csv")
