import { TestBed } from '@angular/core/testing';

import { MLocaldataService } from './m-localdata.service';

describe('MLocaldataService', () => {
  let service: MLocaldataService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MLocaldataService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
