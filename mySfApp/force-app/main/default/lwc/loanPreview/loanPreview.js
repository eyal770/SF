import { LightningElement, wire } from 'lwc';
import getLoanRequestById from '@salesforce/apex/LoanRequestController.getLoanRequestById';

// Lightning Message Service
import { subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import LOAN_REQUEST_CHANNEL from '@salesforce/messageChannel/LoanRequestMessageChannel__c';

export default class LoanPreview extends LightningElement {
    subscription;
    isLoading = false;
    errorMessage = '';
    loan = null;
    customerName = '';

    @wire(MessageContext) messageContext;

    connectedCallback() {
        this.subscribeToChannel();
    }

    disconnectedCallback() {
        // (Optional) Unsubscribe logic could be added here if needed
    }

    subscribeToChannel() {
        if (this.subscription) return;
        this.subscription = subscribe(
            this.messageContext,
            LOAN_REQUEST_CHANNEL,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    async handleMessage(message) {
        this.errorMessage = '';
        this.isLoading = true;

        try {
            // 1) Optimistic display from message
            this.loan = {
                Id: message.loanRequestId,
                LoanAmount__c: message.loanAmount,
                LoanStatus__c: message.loanStatus
            };
            this.customerName = message.customerName;

            // 2) Authoritative refresh from server
            const fresh = await getLoanRequestById({ loanRequestId: message.loanRequestId });
            this.loan = fresh;
            this.customerName = fresh?.Customer__r?.Name || this.customerName;
        } catch (e) {
            this.errorMessage = e?.body?.message || e.message || 'Failed to load loan request.';
        } finally {
            this.isLoading = false;
        }
    }

    handleClear() {
        this.loan = null;
        this.customerName = '';
        this.errorMessage = '';
    }
}
