# Purpose: draw the patient timeline (paper Supplemental Figure 1), as a static
#   image and as an interactive page.
# Needs: functions.R (jitter_days), setup.R (InterventionDate,
#   timeline_jitter_days, timeline_jitter_seed, figures_dir), load_data.R
#   (transplant_data_unprocessed) and process_offers.R
#   (organ_offers_processed).
# Produces: plot1 and the files figures/timeline.png and
#   figures/timeline.html, which Git ignores until the decider clears them.
# The figure is that of the original code, with one privacy change
# (analysis-plan.md section 10): every plotted event is moved by its own random
# shift of up to timeline_jitter_days days, never across day 0, so the figure
# is no more precise than the published static one. The interactive page embeds every plotted
# value, which is why the shift is applied before plotting.

## ---- timeline-follow-up
# Days from day 0 to each candidate's consent and end of follow-up, each
# shifted at random. The end of follow-up is one event: its shifted day is used
# both for the end of the candidate's line and for its end-of-follow-up point.
timeline_follow_up <- transplant_data_unprocessed %>%
  transmute(
    Study_ID,
    consent_day = as.numeric(as.Date(Date_of_consent) - as.Date(InterventionDate)),
    end_day = as.numeric(as.Date(End_Date) - as.Date(InterventionDate))
  ) %>%
  mutate(
    consent_day = jitter_days(consent_day, timeline_jitter_days, timeline_jitter_seed),
    end_day = jitter_days(end_day, timeline_jitter_days, timeline_jitter_seed + 1L)
  )

## ---- timeline-events
# Offers, as declined, accepted but not transplanted, or accepted and
# transplanted, each at its own shifted day.
graphic_data_points_1 <- organ_offers_processed %>%
  mutate(Event = case_when(
    Offer_Acceptance == "No" ~ "HIV offer declined",
    Offer_Acceptance == "Provisional Acceptance" ~ "HIV offer accepted, but not transplanted",
    Offer_Acceptance == "Yes" ~ "HIV offer accepted and transplanted")) %>%
  mutate(endpoint = as.numeric(as.Date(Match_Date) - as.Date(InterventionDate))) %>%
  mutate(endpoint = jitter_days(endpoint, timeline_jitter_days, timeline_jitter_seed + 2L)) %>%
  select(Study_ID, endpoint, Event)

# How follow-up ended, for candidates not transplanted from a donor with HIV,
# at the shifted end of follow-up.
graphic_data_points_2 <- transplant_data_unprocessed %>%
  filter(HIV_transplanted == 0) %>%
  mutate(Event = case_when(
    Transplanted == 1 & HIV_transplanted == 0 ~ "Non-HIV offer accepted and transplanted",
    str_detect(Listing_Status, "Deceased") ~ "Death",
    str_detect(Listing_Status, "Withdrawn") ~ "Permanently delisted",
    TRUE ~ "End of study period")) %>%
  select(Study_ID, Event) %>%
  left_join(select(timeline_follow_up, Study_ID, endpoint = end_day),
            by = "Study_ID", relationship = "one-to-one")

graphic_data_points <- bind_rows(graphic_data_points_1, graphic_data_points_2) %>%
  mutate(Study_ID = as.factor(Study_ID))

rm(graphic_data_points_1, graphic_data_points_2)

## ---- timeline-lines
# Each candidate's follow-up as up to two segments, split at day 0: before the
# intervention (red) and after it (blue). The split logic is the original code's.
graphic_data_lines <- timeline_follow_up %>%
  rename(endpoint_left = consent_day, endpoint_right = end_day) %>%
  mutate(endpoint1_left = case_when(
    endpoint_left < 0 ~ endpoint_left,
    endpoint_left >= 0 ~ NA_real_)) %>%
  mutate(endpoint1_right = case_when(
    endpoint_left < 0 & endpoint_right > 0 ~ 0,
    endpoint_left < 0 & endpoint_right < 0 ~ endpoint_right,
    endpoint_left >= 0 ~ NA_real_)) %>%
  mutate(endpoint2_left = case_when(
    endpoint_left < 0 & endpoint_right > 0 ~ 0,
    endpoint_left > 0 & endpoint_right > 0 ~ endpoint_left,
    endpoint_right <= 0 ~ NA_real_)) %>%
  mutate(endpoint2_right = case_when(
    endpoint_right > 0 ~ endpoint_right,
    endpoint_right <= 0 ~ NA_real_)) %>%
  select(Study_ID, endpoint1_left, endpoint1_right, endpoint2_left, endpoint2_right) %>%
  mutate(Study_ID = as.factor(Study_ID))

## ---- timeline-plot
plot1 <- ggplot() +
  geom_segment(data = graphic_data_lines,
               mapping = aes(x = endpoint2_left, xend = endpoint2_right,
                             y = Study_ID, yend = Study_ID),
               color = "blue") +
  geom_segment(data = graphic_data_lines,
               mapping = aes(x = endpoint1_left, xend = endpoint1_right,
                             y = Study_ID, yend = Study_ID),
               color = "red") +
  geom_vline(xintercept = 0) +
  geom_point(data = graphic_data_points,
             mapping = aes(x = endpoint, y = Study_ID, color = Event, shape = Event),
             alpha = 0.7) +
  labs(y = "Study ID", x = "Days before or after study intervention (Date of Intervention=0)") +
  scale_x_continuous(breaks = seq(-1095, 720, 365)) +
  scale_shape_manual(values = c(0, 1, 2, 3, 4, 5, 6)) +
  theme_classic() +
  theme(legend.position = "bottom")

## ---- save-timeline
# Saved to figures/, which stays out of Git until the figure is cleared.
dir.create(figures_dir, showWarnings = FALSE)
ggsave(file.path(figures_dir, "timeline.png"), plot1, width = 9, height = 7, dpi = 300)

timeline_interactive <- ggplotly(plot1, tooltip = c("y", "color")) %>%
  layout(legend = list(orientation = "h", x = 0, y = -0.2))
htmlwidgets::saveWidget(timeline_interactive, file.path(figures_dir, "timeline.html"),
                        selfcontained = TRUE)
