import { Component, Input, Output, EventEmitter, SimpleChanges  } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MDeleteButtonComponent } from '../m-delete-button/m-delete-button.component';

@Component({
  selector: 'm-table',
  standalone: true,
  imports: [CommonModule, MDeleteButtonComponent],
  templateUrl: './m-table.component.html',
  styleUrl: './m-table.component.css',
  //changeDetection: ChangeDetectionStrategy.OnPush
})
export class MTableComponent {

  @Input() data: any[] = [];
  @Input() filterTerm: string = '';
  @Input() showDeleteButton: boolean = false;
  @Input() showMoreDetails: boolean = false;
  @Input() showCaption: boolean = false;
  @Input() caption: string = 'Table Caption';
  @Input() tableHeaders: any[] = [];
  @Input() columnsToBeDisplayed: string[] = [];
  @Output() remove: EventEmitter<any> = new EventEmitter<any>();
  @Output() navigate: EventEmitter<any> = new EventEmitter<any>();

  private originalData: any[];
  public isStringData: boolean = false;

  constructor() {
    this.originalData = [];
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['data']) {
      this.originalData = [...this.data];
      this.checkDataType();
    }

    if (changes['filterTerm']) {
      this.filterData(this.filterTerm);
    }
  }

  checkDataType(): void {
    if (this.data.length > 0) {
      this.isStringData = typeof this.data[0] === 'string';
    }
  }


  getObjectKeys(obj: any): string[] {
    if (!obj) {
      return [];
    }
    if (this.isStringData) {
      return ['Value'];
    }
    return Object.keys(obj);
  }

  showDetails(item: any) {
    this.navigate.emit(item);
  }

  removeItem(item: any) {
    this.remove.emit(item);
  }

  filterData(searchTerm: string): void {
    if (!searchTerm) {
      this.data = [...this.originalData];
    } else {
      this.data = this.originalData.filter(item =>
        typeof item === 'string'
          ? item.toLowerCase().includes(searchTerm.toLowerCase().trim())
          : Object.values(item).some((value: any) =>
              value.toString().toLowerCase().includes(searchTerm.toLowerCase().trim())
            )
      );
    }
  }
}
