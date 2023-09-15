library(tidyverse)
library(jsonlite)
library(rjson)

# get OTHER stuff (not talks)

# Call the raw json object I saved from the posit api response tab
# which grabs non-talks only (note that neither contain workshops)
raw_json_schedule_nontalks <- fromJSON(file = "data/PositConf2023_Schedule_nontalks_9-14-11pm.json")


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
    purrr::pluck(sectionNum, "items", itemNum, "times", 1, "daySort") %>%
    ymd() %>%
    as.Date() %>% 
    format("%m/%d/%Y")
  
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

# Save the data frame as a csv file so it's easy to put into Notion if I want
write_csv(nontalk_df, "output/PositConf2023_nontalks.csv")
