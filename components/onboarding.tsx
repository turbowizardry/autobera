'use client';

import { useWalletStatus } from '@/hooks/wallet';

import {
  CircleCheck,
  Database,
} from 'lucide-react';

const steps = [
  {
    id: 1,
    type: 'done',
    title: 'Sign in with your account',
    description:
      'To get started, log in with your organization account from your company.',
    href: '#',
  },
  {
    id: 2,
    type: 'in progress',
    title: 'Import data',
    description:
      'Connect your database to the new workspace by using one of 20+ database connectors.',
    href: '#',
  },
  {
    id: 3,
    type: 'open',
    title: 'Create your first report',
    description:
      'Generate your first report by using our pre-built templates or easy-to-use report builder.',
    href: '#',
  },
];

export default function Onboarding() {
  const { walletAddress } = useWalletStatus();

  console.log('walletAddress', walletAddress);

  return (
    <>
      <div className="sm:mx-auto sm:max-w-lg">
        <h3 className="text-2xl font-semibold text-white">
          Hello, Maxime
        </h3>
        <p className="text-gray-300">
          Let's set up your first data workspace
        </p>
        <ul role="list" className="mt-8 space-y-3">
          {steps.map((step) =>
            step.type === 'done' ? (
              <li key={step.id} className="relative p-4">
                <div className="flex items-start">
                  <CircleCheck
                    fill="bg-green-500"
                    className="size-6 shrink-0 text-white"
                    aria-hidden={true}
                  />
                  <div className="ml-3 w-0 flex-1 pt-0.5">
                    <p className="font-medium leading-5 text-white">
                      <a href={step.href} className="focus:outline-none">
                        {/* extend link to entire list card */}
                        <span className="absolute inset-0" aria-hidden={true} />
                        {step.title}
                      </a>
                    </p>
                    <p className="mt-1 text-gray-300 leading-6">
                      {step.description}
                    </p>
                  </div>
                </div>
              </li>
            ) : step.type === 'in progress' ? (
              <li key={step.id} className="rounded-tremor-default bg-gray-800 p-4">
                <div className="flex items-start">
                  <CircleCheck
                    className="size-6 shrink-0 text-white"
                    aria-hidden={true}
                  />
                  <div className="ml-3 w-0 flex-1 pt-0.5">
                    <p className="font-medium leading-5 text-white">
                      {step.title}
                    </p>
                    <p className="mt-1 text-gray-300 leading-6">
                      {step.description}
                    </p>
                    <button
                      type="button"
                      className="mt-4 inline-flex items-center gap-1.5 whitespace-nowrap rounded-tremor-small bg-white px-3 py-2 text-gray-900 font-medium shadow-tremor-input hover:bg-gray-100"
                    >
                      <Database
                        className="-ml-0.5 size-5 shrink-0"
                        aria-hidden={true}
                      />
                      Connect database
                    </button>
                  </div>
                </div>
              </li>
            ) : (
              <li key={step.id} className="relative p-4">
                <div className="flex items-start">
                  <CircleCheck
                    fill="bg-green-500"
                    className="size-6 shrink-0 text-gray-300"
                    aria-hidden={true}
                  />
                  <div className="ml-3 w-0 flex-1 pt-0.5">
                    <p className="font-medium leading-5 text-gray-300">
                      <a href={step.href} className="focus:outline-none">
                        {/* extend link to entire list card */}
                        <span className="absolute inset-0" aria-hidden={true} />
                        {step.title}
                      </a>
                    </p>
                    <p className="mt-1 text-gray-300 leading-6">
                      {step.description}
                    </p>
                  </div>
                </div>
              </li>
            ),
          )}
        </ul>
      </div>
    </>
  );
}