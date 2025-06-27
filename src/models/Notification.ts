import { infoIcon } from '@/shared/icons'
import type { IdType, TextAreaType, TextLabelType, TimestampzType } from "@/shared/types"
import { uid } from "quasar"

/*
TODO
Need to figure out the design for this table.
How do I want notifications to be saved, sorted, and displayed in the app?
*/

interface NotificationParams {
  app_title: TextLabelType
  heading: TextLabelType
  message: TextAreaType
  icon?: string
  color?: string
}

export class Notification {
  id: IdType
  created_at: TimestampzType
  app_title: TextLabelType
  heading: TextLabelType
  message: TextAreaType
  icon: string
  color: string

  constructor(params: NotificationParams) {
    this.id = uid()
    this.created_at = new Date().toISOString()
    this.app_title = params.app_title
    this.heading = params.heading
    this.message = params.message
    this.icon = params.icon || infoIcon
    this.color = params.color || 'primary'
  }
}
