library(tidyverse)

# turn each output csv into a google calendar compatible csv

# import the output csv containing the talks only (from get_talks.R)
talks_csv <- read_csv("output/PositConf2023_talks.csv")

# import the output csv containing the nontalks only (from get_nontalks.R)
# again, note that neither contain workshops!
nontalks_csv <- read_csv("output/PositConf2023_nontalks.csv")

# we want to combine these, but the nontalks df needs a "speaker" column
# create one and leave that column empty (full of NAs is fine)

nontalks_csv$speaker <- NA

# put the speaker column in the right place so we can rbind them (swap col 7 & 8)

nontalks_csv <- nontalks_csv[c(1:6, 8, 7)]

# combine these files by rbinding them

all_events <- rbind(talks_csv, nontalks_csv)

### IF YOU'RE USING THIS AND YOU DON'T WANT SOME OF THE CATEGORIES, ############
### NOW IS THE TIME TO FILTER THEM OUT! To see all unique type: unique(all_events$type)

# example of filtering so that your resulting event csv file has only talks
# all_events <- all_events %>% filter(type == "Talk")

# example of filtering to just talks, keynotes, and lightning talks
# all_events <- all_events %>% filter(type %in% c("Talk", "Keynote", "Lightning"))

# example of filtering out "Ask Me Anything" and "The Lounge" types
# since Ask Me Anythings are virtual and The Lounge is open almost all day
all_events <- all_events %>% filter(!type %in% c("Ask Me Anything", "The Lounge"))

# now we need the columns in a format google will understand for our csv:

# Subject
# (Required) The name of the event
# Example: Final exam
# Start Date
# (Required) The first day of the event
# Example: 05/30/2020
# Start Time
# The time the event begins
# Example: 10:00 AM
# End Date
# The last day of the event
# Example: 05/30/2020
# End Time
# The time the event ends
# Example: 1:00 PM
# All Day Event
# Whether the event is an all-day event. 
# If it’s an all-day event, enter True. 
# If it isn’t an all-day event, enter False.
# Example: False
# Description
# Description or notes about the event
# Example: "50 multiple choice questions and two essay questions"
# Location
# The location for the event
# Example: "Columbia, Schermerhorn 614"

# Most of our columns are in the right format, but we will want to combine
# speaker and abstract into one value if we want to add it as the description

all_events$description <- paste0("Speaker: ", 
                                 all_events$speaker, 
                                 "; Abstract: ", 
                                 all_events$abstract)

# type and title will become one for the subject

all_events$subject <- paste0(all_events$type, 
                             " - ", 
                             all_events$title)

# now we can drop the speaker and abstract columns, as well as title and type
all_events$speaker <- NULL
all_events$abstract <- NULL
all_events$title <- NULL
all_events$type <- NULL

# I don't think we need an end date, but just to be sure, let's add one that's 
# the duplicate of the start date

all_events$end_date <- all_events$date

# Let's add an all day event column to match the formatting above

all_events$all_day_event <- "False"

# Let's rearrange the columns to be in the order of
# subject, start date, start time, end date, end time, all day event, 
# description, location

all_events <- all_events[c(6, 1, 2, 7, 3, 8, 5, 4)]

# Now, let's make each of our columns into what they need to be in our exported
# csv file, which means they need spaces in their column names

colnames(all_events) <- c("Subject", "Start Date", "Start Time", "End Date", "End Time",
                       "All Day Event", "Description", "Location")


# write the csv file!

write_csv(all_events, "output/PositConf2023_all_events_cal.csv",
          col_names = TRUE)

# DO NOT, I REPEAT, DO NOT GO OPEN THE CSV IN EXCEL, IT WILL RUIN IT IF YOU SAVE IT THERE

# The resulting csv file can then be uploaded into google calendar like this: 
# 0. (optional) Go create a new calendar called Posit Conf 2023
# 1. Open Google Calendar.
# 2. In the top right, click Settings Settings (gear icon), then click Settings.
# 3. In the menu on the left, click Import & Export.
# 4. Click Select file from your computer and select the csv file we made.
# 5. Choose which calendar to add the imported events to (I created a Posit Conf 2023 one beforehand)
# By default, events are imported into your primary calendar.
# 6. Click Import.