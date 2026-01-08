import { EmailClient } from '@azure/communication-email'
import { Injectable } from '@nestjs/common'
import { SafeConfigService } from 'src/common'

interface EmailParameters {
    otp?: string
    password?: string
    newPassword?: string
    [key: string]: any
}

@Injectable()
export class AzureEmailService {    
    private readonly connectionString: string
    private readonly sender: string

    // Must be set in .env
    constructor(config: SafeConfigService) {
        this.connectionString = config.getString('AZURE_CONNECTION_STRING')
        this.sender = config.getString('AZURE_MAILER_SENDER_ADDRESS')
    }

    static Template = {
        FATAL_EXCEPTION: 'FATAL_EXCEPTION',
        FIND_PASSWORD: 'FIND_PASSWORD'
    }

    async sendEmailWithAzure(to: string, templateId: string, parameters: EmailParameters) {
        const client = new EmailClient(this.connectionString)
        
        const { subject, body } = this.getTemplate(templateId, parameters)

        const emailMessage = {
            senderAddress: this.sender,
            content: {
                subject: subject,
                plainText: body,
                html: `<html><body>${body}</body></html>`,
            },
            recipients: {
                to: [{ address: to }],
            },
        }

        try {
            const poller = await client.beginSend(emailMessage)
            const result = await poller.pollUntilDone()
            return result
        } catch (error) {
            throw error
        }
    }

    private getTemplate(templateId: string, parameters: EmailParameters): { subject: string, body: string } {
        switch (templateId) {
            case AzureEmailService.Template.FATAL_EXCEPTION:
                return {
                    subject: "[XRCloud] FatalException Occurred.",
                    body: `DATE: ${parameters.date}<br>URL: ${parameters.url}<br>BODY: ${parameters.body}<br>MSG: ${parameters.msg}`
                }
            case AzureEmailService.Template.FIND_PASSWORD:
                return {
                    subject: "[CNU Admin] Admin account created.",
                    body: `${parameters.code}<br>The code above will expire in 5 minutes.`  
                }            
            default:
                throw new Error('Invalid templateId')
        }
    }
}
